defmodule Refactorex.Refactor.Variable.UnderscoreNotUsed do
  use Refactorex.Refactor,
    title: "Underscore variables not used",
    kind: "quickfix",
    works_on: :line

  alias Refactorex.Refactor.Dataflow

  def can_refactor?(%{node: node}, line) do
    node
    |> Dataflow.group_variables_semantically()
    |> Enum.any?(fn
      {{name, _, _} = declaration, []} ->
        AST.starts_at?(declaration, line) and
          not String.starts_with?("#{name}", "_")

      {_declaration, _usages} ->
        false
    end)
    |> then(&if &1, do: true, else: :skip)
  end

  def refactor(%{node: node} = zipper, line) do
    node
    |> Dataflow.group_variables_semantically()
    |> Stream.filter(&same_line_and_no_usages?(&1, line))
    |> Enum.reduce(zipper, fn
      {declaration, []}, zipper ->
        zipper
        |> AST.go_to_node(declaration)
        |> Z.update(fn {name, meta, nil} ->
          {String.to_atom("_#{name}"), meta, nil}
        end)
    end)
  end

  defp same_line_and_no_usages?({declaration, usages}, line),
    do: AST.starts_at?(declaration, line) and usages == []
end
