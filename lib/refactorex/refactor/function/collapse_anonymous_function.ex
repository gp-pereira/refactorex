defmodule Refactorex.Refactor.Function.CollapseAnonymousFunction do
  use Refactorex.Refactor,
    title: "Collapse anonymous function",
    kind: "refactor.rewrite",
    works_on: :selection

  alias Refactorex.Refactor.{
    Block,
    Dataflow,
    Variable
  }

  def can_refactor?(%{node: {:fn, _, [{:->, _, [[], _]}]}}, _), do: false

  def can_refactor?(%{node: {:fn, _, [{:->, _, [args, body]}]} = node}, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      Block.has_multiple_statements?(body) ->
        false

      not Variable.plain_variables?(args) ->
        false

      some_arg_not_used?(args, Dataflow.group_variables_semantically(node)) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(%{node: {_, _, [{:->, _, [args, body]}]} = node} = zipper, _) do
    new_args = for i <- 1..length(args), do: {:&, [], [i]}

    Z.replace(
      zipper,
      {:&, [], [Variable.replace_variables_by_values(body, args, new_args, node)]}
    )
  end

  defp some_arg_not_used?(args, variable_groups),
    do: not Enum.all?(args, &(variable_groups[&1] != []))
end
