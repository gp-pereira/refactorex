defmodule Refactorex.Refactor.Constant.RenameConstant do
  use Refactorex.Refactor,
    title: "Rename constant",
    kind: "source",
    works_on: :selection

  def can_refactor?(zipper, {:@, _, [selection]}),
    do: can_refactor?(zipper, selection)

  def can_refactor?(%{node: {id, meta, _}}, selection),
    do: AST.equal?({id, meta, nil}, selection)

  def can_refactor?(_, _), do: false

  def refactor(%{node: {id, _, _}} = zipper, _) do
    zipper
    |> Z.top()
    |> Z.traverse(fn
      %{node: {:@, constant_meta, [{^id, meta, block}]}} = zipper ->
        Z.replace(
          zipper,
          {:@, constant_meta, [{placeholder(), meta, block}]}
        )

      zipper ->
        zipper
    end)
  end
end
