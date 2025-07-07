defmodule Refactorex.Refactor.Case.ConvertToWith do
  use Refactorex.Refactor,
    title: "Convert case to with",
    kind: "refactor.rewrite",
    works_on: :line

  def can_refactor?(%{node: {:case, _, [{:=, _, _}, _]}}, _), do: false
  def can_refactor?(%{node: {:case, _, [_, [{_, {_, _, []}}]]}}, _), do: false

  def can_refactor?(%{node: {:case, _, _} = node} = zipper, line) do
    cond do
      not AST.starts_at?(node, line) ->
        false

      match?(%{node: {:|>, _, [_, ^node]}}, Z.up(zipper)) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(%{node: {:case, _, [expression, [block]]}} = zipper, _) do
    {_, [{:->, _, [[first_pattern], first_block]} | other_clauses]} = block

    Z.replace(zipper, {
      :with,
      [do: [], end: []],
      [
        {:<-, [], [first_pattern, expression]},
        [{{:__block__, [], [:do]}, first_block} | else_clauses(other_clauses)]
      ]
    })
  end

  defp else_clauses([]), do: []
  defp else_clauses(other_clauses), do: [{{:__block__, [], [:else]}, other_clauses}]
end
