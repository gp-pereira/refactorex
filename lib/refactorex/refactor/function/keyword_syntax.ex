defmodule Refactorex.Refactor.Function.KeywordSyntax do
  use Refactorex.Refactor,
    title: "Rewrite function with keyword syntax",
    kind: "refactor.rewrite"

  def can_refactor?(%{node: {:def, meta, _}} = zipper, %{start: %{line: line}}) do
    cond do
      # keyword functions don't have an :end
      is_nil(meta[:end][:line]) ->
        :skip

      # range start is outside function declaration
      line < meta[:do][:line] or line > meta[:end][:line] ->
        :skip

      function_block_has_inner_blocks?(zipper) ->
        :skip

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(zipper) do
    zipper
    |> Z.update(fn {:def, meta, macro} ->
      {:def, Keyword.drop(meta, [:do, :end]), macro}
    end)
    |> go_to_function_block()
    |> Z.update(fn {{:__block__, meta, [:do]}, macro} ->
      {{:__block__, Keyword.put(meta, :format, :keyword), [:do]}, macro}
    end)
  end

  defp function_block_has_inner_blocks?(zipper) do
    zipper
    |> go_to_function_block()
    |> then(&match?(%{node: {{:__block__, _, _}, {:__block__, _, [_ | _]}}}, &1))
  end

  defp go_to_function_block(zipper) do
    zipper
    |> Z.down()
    |> Z.right()
    |> Z.down()
  end
end
