defmodule Refactorex.Refactor.Pipeline.RemovePipe do
  use Refactorex.Refactor,
    title: "Remove pipe",
    kind: "refactor.rewrite",
    works_on: :line

  def can_refactor?(%{node: {:|>, meta, _}}, line),
    do: meta[:line] == line

  def can_refactor?(_, _), do: false

  def refactor(zipper, _) do
    zipper
    |> Z.update(fn {:|>, _, [arg, {id, meta, rest}]} ->
      {id, meta, [arg | rest]}
    end)
  end
end
