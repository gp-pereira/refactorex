defmodule Refactorex.Refactor.Function.RegularSyntax do
  use Refactorex.Refactor,
    title: "Rewrite keyword function with regular syntax",
    kind: "refactor.rewrite"

  def can_refactor?(%{node: {:def, meta, _}} = zipper, %{start: %{line: line}}) do
    %{node: {{:__block__, block_meta, _}, _}} = go_to_function_block(zipper)

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
    |> Z.update(fn {:def, meta, macro} ->
      {:def, Keyword.merge(meta, do: [], end: []), macro}
    end)
    |> go_to_function_block()
    |> Z.update(fn {{:__block__, meta, [:do]}, macro} ->
      {{:__block__, Keyword.drop(meta, [:format]), [:do]}, macro}
    end)
  end

  defp go_to_function_block(zipper) do
    zipper
    |> Z.down()
    |> Z.right()
    |> Z.down()
  end
end
