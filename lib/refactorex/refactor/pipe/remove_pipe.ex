defmodule Refactorex.Refactor.Pipe.RemovePipe do
  use Refactorex.Refactor,
    title: "Remove pipe",
    kind: "refactor.rewrite",
    works_on: :line

  def can_refactor?(%{node: {:|>, _, _} = node}, line),
    do: Sourceror.get_line(node) == line

  def can_refactor?(_, _), do: false

  def refactor(zipper) do
    zipper
    |> Z.update(fn {:|>, _, [arg, {id, meta, rest}]} ->
      {id, meta, [arg | rest]}
    end)
  end
end
