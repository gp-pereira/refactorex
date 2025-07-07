defmodule Refactorex.Refactor.Case.ConvertFromWith do
  use Refactorex.Refactor,
    title: "Convert with to case",
    kind: "refactor.rewrite",
    works_on: :line

  def can_refactor?(%{node: {:with, _, [_, _, _ | _]}}, _), do: false
  def can_refactor?(%{node: {:with, _, _} = node}, line), do: AST.starts_at?(node, line)
  def can_refactor?(_, _), do: false

  def refactor(%{node: {:with, _, [first_clause, blocks]}} = zipper, _) do
    {:<-, _, [first_pattern, first_expression]} = first_clause
    [{{_, _, [:do]}, match_block} | else_block] = blocks

    Z.replace(zipper, {
      :case,
      [do: [], end: []],
      [
        first_expression,
        [
          {
            {:__block__, [], [:do]},
            [
              {:->, [], [[first_pattern], first_block(match_block)]}
              | other_clauses(else_block)
            ]
          }
        ]
      ]
    })
  end

  defp first_block({:__block__, _, []}), do: {:__block__, [], [nil]}
  defp first_block(match_block), do: match_block

  defp other_clauses([]), do: [{:->, [], [[{:other, [], nil}], {:other, [], nil}]}]
  defp other_clauses([{{:__block__, _, [:else]}, else_clauses}]), do: else_clauses
end
