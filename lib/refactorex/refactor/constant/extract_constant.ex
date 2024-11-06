defmodule Refactorex.Refactor.Constant.ExtractConstant do
  use Refactorex.Refactor,
    title: "Extract constant",
    kind: "refactor.extract",
    works_on: :selection

  alias Refactorex.Refactor.{
    Module,
    Variable
  }

  @constant_name "extracted_constant"

  def can_refactor?(%{node: {id, _, _}}, _)
      when id in ~w(@ &)a,
      do: false

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      not Module.inside_one?(zipper) ->
        false

      Enum.any?(Variable.list_variables(node)) ->
        :skip

      true ->
        true
    end
  end

  def refactor(%{node: to_be_constant} = zipper, _) do
    name = next_available_constant_name(zipper)

    zipper
    |> Z.update(fn _ -> {:@, [], [{name, [], nil}]} end)
    |> Module.update_scope(fn module_scope ->
      position = where_to_place_constant(module_scope, to_be_constant)
      {before, rest} = Enum.split(module_scope, position)

      before ++ [{:@, [], [{name, [], [to_be_constant]}]} | rest]
    end)
  end

  def next_available_constant_name(zipper) do
    Module.next_available_name(
      zipper,
      @constant_name,
      &match?({:@, _, _}, &1),
      fn {_, _, [{name, _, _}]} -> name end
    )
  end

  defp where_to_place_constant(module_scope, to_be_constant) do
    constants_used = find_constants_used(to_be_constant)

    module_scope
    |> Stream.with_index()
    |> Stream.map(fn
      {{id, _, _}, i} when id in ~w(use alias import require)a ->
        i + 1

      {{:@, _, [{:behaviour, _, _}]}, i} ->
        i + 1

      {{:@, _, [constant]}, i} ->
        if Variable.member?(constants_used, constant), do: i + 1, else: 0

      _ ->
        0
    end)
    |> Enum.max()
  end

  defp find_constants_used(to_be_constant) do
    to_be_constant
    |> AST.find(&match?({:@, _, [{_, _, nil}]}, &1))
    |> Enum.map(fn {:@, _, [constant]} -> constant end)
  end
end
