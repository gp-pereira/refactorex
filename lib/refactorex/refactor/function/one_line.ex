defmodule Refactorex.Refactor.Function.OneLine do
  use Refactorex.Refactor

  def do_refactor(%{node: {:def, _, _}} = zipper, false, position) do
    if can_refactor?(position, zipper),
      do: {:halt, one_line_function(zipper), true},
      else: {:skip, zipper, false}
  end

  def do_refactor(zipper, bool, _), do: {:cont, zipper, bool}

  defp can_refactor?(%{line: line}, %{node: {:def, meta, _}} = zipper) do
    cond do
      # one line functions don't have an :end
      is_nil(meta[:end][:line]) ->
        false

      # selection start is outside function declaration
      line < meta[:do][:line] or line > meta[:end][:line] ->
        false

      function_block_has_inner_blocks?(zipper) ->
        false

      true ->
        true
    end
  end

  defp one_line_function(zipper) do
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
