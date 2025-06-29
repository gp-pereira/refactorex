defmodule Refactorex.Refactor.Function.UseRegularSyntax do
  use Refactorex.Refactor,
    title: "Rewrite keyword function using regular syntax",
    kind: "refactor.rewrite",
    works_on: :line

  alias Refactorex.Refactor.Function

  def can_refactor?(%{node: node} = zipper, line) do
    cond do
      not Function.definition?(node) ->
        false

      not AST.starts_at?(node, line) ->
        false

      true ->
        %{node: {{:__block__, block_meta, _}, _}} = Function.go_to_block(zipper)

        # only keyword functions have format tag
        block_meta[:format] == :keyword
    end
  end

  def refactor(zipper, _) do
    zipper
    |> Z.update(fn {function, meta, macro} ->
      {function, Keyword.merge(meta, do: [], end: []), macro}
    end)
    |> Function.go_to_block()
    |> Z.update(fn {{:__block__, meta, [:do]}, macro} ->
      {{:__block__, Keyword.drop(meta, [:format]), [:do]}, macro}
    end)
  end
end
