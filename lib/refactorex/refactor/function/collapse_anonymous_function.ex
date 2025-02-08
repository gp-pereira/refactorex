defmodule Refactorex.Refactor.Function.CollapseAnonymousFunction do
  use Refactorex.Refactor,
    title: "Collapse anonymous function",
    kind: "refactor.rewrite",
    works_on: :selection

  alias Refactorex.Refactor.{
    Block,
    Variable
  }

  def can_refactor?(%{node: {:fn, _, [{:->, _, [[], _]}]}}, _), do: false

  def can_refactor?(%{node: {:fn, _, [{:->, _, [args, body]}]} = node}, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      Block.has_multiple_statements?(body) ->
        false

      args != Variable.list_unpinned_variables(args) ->
        false

      true ->
        used_variables = Variable.list_unique_variables(body)
        Enum.all?(args, &Variable.member?(used_variables, &1))
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
end
