defmodule Refactorex.Refactor.Function.UseKeywordSyntax do
  use Refactorex.Refactor,
    title: "Rewrite function using keyword syntax",
    kind: "refactor.rewrite"

  import Refactorex.Refactor.Function

  def can_refactor?(%{node: {id, meta, _}} = zipper, range) when function_id?(id) do
    %{start: %{line: line}} = range

    cond do
      # keyword functions don't have an :end
      is_nil(meta[:end]) ->
        :skip

      # range start is outside function declaration
      line < meta[:line] or line > meta[:line] ->
        :skip

      function_has_multiple_statements?(zipper) ->
        :skip

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(zipper) do
    zipper
    |> Z.update(fn {id, meta, macro} ->
      {id, Keyword.drop(meta, [:do, :end]), macro}
    end)
    |> go_to_function_block()
    |> Z.update(fn {{:__block__, meta, [:do]}, macro} ->
      {{:__block__, Keyword.put(meta, :format, :keyword), [:do]}, macro}
    end)
  end

  defp function_has_multiple_statements?(zipper) do
    zipper
    |> go_to_function_block()
    |> then(fn
      %{node: {{:__block__, _, _}, {:__block__, _, [{{:__block__, _, _}, _} | _]}}} ->
        false

      %{node: {{:__block__, _, _}, {:__block__, _, [_ | _]}}} ->
        true

      _ ->
        false
    end)
  end
end
