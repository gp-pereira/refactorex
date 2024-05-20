defmodule Refactorex.Refactor.Pipe.RemovePipe do
  use Refactorex.Refactor,
    title: "Remove pipe",
    kind: "refactor.rewrite",
    works_on: :line

  def can_refactor?(%{node: {:|>, _, _} = node}, line),
    do: AST.starts_at?(node, line)

  def can_refactor?(_, _), do: false

  def refactor(zipper, _) do
    zipper
    |> Z.update(fn {:|>, _, [arg, {id, meta, rest}]} ->
      {id, meta, [arg | rest]}
    end)
  end
end
