defmodule Refactorex.Refactor.Pipe.RemovePipe do
  use Refactorex.Refactor,
    title: "Remove pipe",
    kind: "refactor.rewrite"

  def can_refactor?(%{node: {:|>, _, _} = node}, range) do
    cond do
      not SelectionRange.empty?(range) ->
        :skip

      not SelectionRange.starts_on_node_line?(range, node) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(zipper) do
    zipper
    |> Z.update(fn {:|>, _, [arg, {id, meta, rest}]} ->
      {id, meta, [arg | rest]}
    end)
  end
end
