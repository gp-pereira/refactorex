defmodule Refactorex.Refactor.Pipeline.RemoveIOInspect do
  use Refactorex.Refactor,
    title: "Remove IO.inspect",
    kind: "quickfix",
    works_on: :line

  def can_refactor?(%{node: {:., _, [{_, _, [:IO]}, :inspect]} = node}, line),
    do: AST.starts_at?(node, line)

  def can_refactor?(_, _), do: false

  def refactor(%{node: io_inspect} = zipper, line) do
    case parent = Z.up(zipper) do
      %{node: {^io_inspect, _, [{id, _, _} = arg | _]}} when id != :__block__ ->
        Z.replace(parent, arg)

      %{node: {^io_inspect, _, _}} ->
        refactor(parent, line)

      %{node: {:|>, _, [arg, ^io_inspect]}} ->
        Z.replace(parent, arg)

      %{node: {:/, _, [^io_inspect, {:__block__, _, _}]}} ->
        refactor(parent, line)

      %{node: {:&, _, [^io_inspect]}} ->
        Z.replace(parent, {:&, [], [{:&, [], [1]}]})
    end
  end
end
