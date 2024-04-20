defmodule Refactorex.Refactor.Function.UseRegularSyntax do
  use Refactorex.Refactor,
    title: "Rewrite keyword function using regular syntax",
    kind: "refactor.rewrite"

  import Refactorex.Refactor.Function

  def can_refactor?(%{node: {id, _, _} = node} = zipper, range) when function_id?(id) do
    %{node: {{:__block__, block_meta, _}, _}} = go_to_function_block(zipper)

    cond do
      # only keyword functions have format tag
      block_meta[:format] != :keyword ->
        :skip

      not SelectionRange.starts_on_node_line?(range, node) ->
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
