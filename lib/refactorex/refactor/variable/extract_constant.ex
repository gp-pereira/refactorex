defmodule Refactorex.Refactor.Variable.ExtractConstant do
  use Refactorex.Refactor,
    title: "Extract module constant",
    kind: "refactor.extract",
    works_on: :node

  alias Refactorex.Refactor.{
    Module,
    Variable
  }

  def can_refactor?(%{node: {:@, _, _}}, _), do: false

  def can_refactor?(%{node: node} = zipper, node) do
    cond do
      not Module.inside_one?(zipper) ->
        :skip

      not Enum.empty?(Variable.find_variables(node)) ->
        :skip

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(%{node: constant} = zipper) do
    constant_name = available_constant_name(zipper)

    zipper
    |> Z.update(fn _ -> {:@, [], [{constant_name, [], nil}]} end)
    |> Module.update_scope(fn module_scope ->
      position = where_to_place_constant(module_scope, constant)
      {before, rest} = Enum.split(module_scope, position)

      before ++ [{:@, [], [{constant_name, [], [constant]}]} | rest]
    end)
  end

  defp where_to_place_constant(module_scope, constant) do
    constants_used = Variable.find_constants_used(constant)

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

  defp available_constant_name(zipper) do
    zipper
    |> Module.find_in_scope(&match?({:@, _, _}, &1))
    |> Enum.reduce("extracted_constant", fn
      {_, _, [{constant_name, _, _}]}, current_name ->
        case Atom.to_string(constant_name) do
          "extracted_constant" ->
            "extracted_constant1"

          "extracted_constant" <> i ->
            "extracted_constant#{String.to_integer(i) + 1}"

          _ ->
            current_name
        end
    end)
    |> String.to_atom()
  end
end
