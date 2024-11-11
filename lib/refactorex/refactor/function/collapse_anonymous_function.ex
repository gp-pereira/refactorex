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

  def refactor(%{node: {_, _, [{:->, _, [args, body]}]}} = zipper, _) do
    Z.replace(
      zipper,
      {:&, [],
       [
         args
         |> Stream.with_index(1)
         |> Enum.reduce(body, fn {{name, _, _}, i}, body ->
           Variable.replace_usages_by_value(body, name, {:&, [], [i]})
         end)
       ]}
    )
  end
end
