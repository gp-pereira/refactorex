defmodule Refactorex.Refactor.Alias.SortNestedAliases do
  use Refactorex.Refactor,
    title: "Sort nested aliases",
    kind: "quickfix",
    works_on: :line

  def can_refactor?(%{node: {:alias, _, _} = node} = zipper, line) do
    cond do
      not AST.starts_at?(node, line) ->
        false

      zipper == refactor(zipper, line) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(zipper, _) do
    Z.traverse(zipper, fn
      %{node: {{:., _, [_, :{}]} = before, meta, aliases}} = zipper ->
        Z.replace(zipper, {before, meta, sort_aliases(aliases)})

      zipper ->
        zipper
    end)
  end

  defp sort_aliases(aliases) do
    Enum.sort(aliases, fn
      {{:., _, [{_, _, a}, :{}]}, _, _}, {:__aliases__, _, b} ->
        a < b

      {:__aliases__, _, a}, {{:., _, [{_, _, b}, :{}]}, _, _} ->
        a < b

      {:__aliases__, _, a}, {:__aliases__, _, b} ->
        a < b
    end)
  end
end
