defmodule Refactorex.Refactor.Function.UseKeywordSyntax do
  use Refactorex.Refactor,
    title: "Rewrite function using keyword syntax",
    kind: "refactor.rewrite",
    works_on: :line

  alias Refactorex.Refactor.{Block, Function}

  def can_refactor?(%{node: {_, meta, [_, [body]]} = node}, line) do
    cond do
      not Function.definition?(node) ->
        false

      # keyword functions don't have :do tag
      is_nil(meta[:do]) ->
        :skip

      not AST.starts_at?(node, line) ->
        false

      Block.has_multiple_statements?(body) ->
        :skip

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(zipper, _) do
    zipper
    |> Z.update(fn {id, meta, macro} ->
      {id, Keyword.drop(meta, [:do, :end]), macro}
    end)
    |> Function.go_to_block()
    |> Z.update(fn {{:__block__, meta, [:do]}, macro} ->
      {{:__block__, Keyword.put(meta, :format, :keyword), [:do]}, macro}
    end)
  end
end
