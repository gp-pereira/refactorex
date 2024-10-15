defmodule Refactorex.Refactor.IfElse.UseRegularSyntax do
  use Refactorex.Refactor,
    title: "Rewrite if else using regular syntax",
    kind: "refactor.rewrite",
    works_on: :line

  def can_refactor?(%{node: {:if, _, [_, [if_block | _]]} = node}, line) do
    {{:__block__, meta, _}, _} = if_block

    # only keyword if else has format tag
    AST.starts_at?(node, line) and meta[:format] == :keyword
  end

  def can_refactor?(_, _), do: false

  def refactor(zipper, _) do
    Z.update(zipper, fn
      {:if, meta, [condition, blocks]} ->
        {:if, Keyword.merge(meta, do: [], end: []),
         [
           condition,
           Enum.map(blocks, &remove_keyword_syntax/1)
         ]}
    end)
  end

  defp remove_keyword_syntax({{:__block__, meta, tag}, inner_block}),
    do: {{:__block__, Keyword.delete(meta, :format), tag}, inner_block}
end
