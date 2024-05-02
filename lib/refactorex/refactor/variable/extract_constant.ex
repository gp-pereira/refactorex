defmodule Refactorex.Refactor.Variable.ExtractConstant do
  use Refactorex.Refactor,
    title: "Extract constant",
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
    zipper
    |> Z.update(fn _ -> {:@, [], [{:extracted_constant, [], nil}]} end)
    |> Module.update_scope(fn module_scope ->
      position = where_to_place_constant(module_scope, constant)
      {before, rest} = Enum.split(module_scope, position)

      before ++ [{:@, [], [{:extracted_constant, [], [constant]}]} | rest]
    end)
  end

  defp where_to_place_constant(module_scope, constant) do
    used_constants = Variable.find_constants(constant)

    Enum.reduce(module_scope, 0, fn
      {id, _, _}, position when id in ~w(use alias import require)a ->
        position + 1

      {:@, _, [{:behaviour, _, _}]}, position ->
        position + 1

      {:@, _, [constant]}, position ->
        if Variable.member?(used_constants, constant),
          do: position + 1,
          else: position

      _, position ->
        position
    end)
  end
end
