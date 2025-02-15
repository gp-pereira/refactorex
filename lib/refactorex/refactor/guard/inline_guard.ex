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

      Guard.definition?(AST.up(zipper, 2)) ->
        false

      is_nil(Guard.find_definition(zipper)) ->
        false

      true ->
        true
    end
  end

  def refactor(%{node: {_, _, call_values}} = zipper, _) do
    {_, _, [{_, _, [{_, _, args}, body]}]} = definition = Guard.find_definition(zipper)

    body
    |> Variable.replace_variables_by_values(args, call_values, definition)
    |> then(&Z.replace(zipper, &1))
  end
end
