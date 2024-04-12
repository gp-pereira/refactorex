defmodule Refactorex.Refactor.Pipe.RemovePipe do
  use Refactorex.Refactor,
    title: "Remove pipe",
    kind: "refactor.rewrite"

  def can_refactor?(%{node: {:|>, meta, _}}, range),
    do: same_start_line?(range, meta)

  def can_refactor?(_, _), do: false

  def refactor(zipper) do
    zipper
    |> Z.update(fn {:|>, _, [arg, {id, meta, rest}]} ->
      {id, meta, [arg | rest]}
    end)
  end
end
