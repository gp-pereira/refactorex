defmodule Refactorex.Refactor.Function.RegularSyntax do
  use Refactorex.Refactor,
    title: "Rewrite keyword function using regular syntax",
    kind: "refactor.rewrite"

  defguardp function?(tag) when tag in ~w(def defp)a

  def can_refactor?(%{node: {tag, meta, _}} = zipper, range) when function?(tag) do
    %{node: {{:__block__, block_meta, _}, _}} = go_to_function_block(zipper)
    %{start: %{line: line}} = range

    cond do
      # only keyword functions have format tag
      block_meta[:format] != :keyword ->
        :skip

      # range start is outside function declaration
      line < meta[:line] or line > block_meta[:line] ->
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

  def go_to_function_block(zipper) do
    zipper
    |> Z.down()
    |> Z.right()
    |> Z.down()
  end
end
