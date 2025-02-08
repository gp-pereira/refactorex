defmodule Refactorex.Refactor.Variable.RenameVariable do
  use Refactorex.Refactor,
    title: "Rename variable",
    kind: "refactor.rename",
    works_on: :selection

  alias Refactorex.Refactor.Variable

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      not Variable.at_one?(zipper) ->
        false

      not Variable.was_declared?(zipper, selection) ->
        false

      true ->
        true
    end
  end

  def refactor(%{node: variable} = zipper, _) do
    all_references = Variable.find_all_references(zipper, variable)

    zipper
    |> Z.top()
    |> Z.traverse(fn %{node: node} = zipper ->
      if Enum.member?(all_references, node) do
        Z.update(zipper, fn {_, meta, nil} ->
          {placeholder(), meta, nil}
        end)
      else
        zipper
      end
    end)
  end
end
