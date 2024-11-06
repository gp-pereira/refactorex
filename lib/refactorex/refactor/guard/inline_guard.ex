defmodule Refactorex.Refactor.Guard.InlineGuard do
  use Refactorex.Refactor,
    title: "Inline guard",
    kind: "refactor.inline",
    works_on: :selection

  alias Refactorex.Refactor.{
    Guard,
    Module,
    Variable
  }

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      not Module.inside_one?(zipper) ->
        false

      not Guard.guard_statement?(zipper) ->
        false

      is_nil(Guard.find_definition(zipper)) ->
        false

      true ->
        true
    end
  end

  def refactor(zipper, _), do: Z.replace(zipper, replace_guard_args_by_call_values(zipper))

  defp replace_guard_args_by_call_values(%{node: {_, _, call_values}} = zipper) do
    {_, _, [{_, _, [{_, _, guard_args}, guard_block]}]} = Guard.find_definition(zipper)

    args_to_values =
      [guard_args, call_values]
      |> Enum.zip()
      |> Map.new(fn {{id, _, _}, value} -> {id, value} end)

    guard_block
    |> Z.zip()
    |> Z.traverse_while(fn
      %{node: {id, _, _}} = zipper ->
        if Variable.at_one?(zipper),
          do: {:skip, Z.replace(zipper, args_to_values[id])},
          else: {:cont, zipper}

      zipper ->
        {:cont, zipper}
    end)
    |> Z.node()
  end
end
