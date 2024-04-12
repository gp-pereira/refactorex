defmodule Refactorex.Refactor.Function.UseRegularSyntax do
  use Refactorex.Refactor,
    title: "Rewrite keyword function using regular syntax",
    kind: "refactor.rewrite"

  import Refactorex.Refactor.Function

  def can_refactor?(%{node: {id, meta, _}} = zipper, range) when function_id?(id) do
    %{node: {{:__block__, block_meta, _}, _}} = go_to_function_block(zipper)
    %{start: %{line: line}} = range

    cond do
      # only keyword functions have format tag
      block_meta[:format] != :keyword ->
        :skip

      # range start is outside function declaration
      line < meta[:line] or line > meta[:line] ->
        :skip

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(zipper) do
    zipper
    |> Z.update(fn {function, meta, macro} ->
      {function, Keyword.merge(meta, do: [], end: []), macro}
    end)
    |> go_to_function_block()
    |> Z.update(fn {{:__block__, meta, [:do]}, macro} ->
      {{:__block__, Keyword.drop(meta, [:format]), [:do]}, macro}
    end)
  end
end
