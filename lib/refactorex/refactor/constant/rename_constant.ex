defmodule Refactorex.Refactor.Constant.RenameConstant do
  use Refactorex.Refactor,
    title: "Rename constant",
    # check
    kind: "refactor.rewrite",
    works_on: :selection

  def can_refactor?(%{node: {id, meta, _}}, selection),
    do: AST.equal?({id, meta, nil}, selection)

  def can_refactor?(_, _), do: false

  def refactor(%{node: _node} = zipper, _) do
    zipper
    |> Z.update(fn {_, meta, block} ->
      {identifier_placeholder(), meta, block}
    end)
  end
end
