defmodule Refactorex.Refactor.Constant.InlineConstant do
  use Refactorex.Refactor,
    title: "Inline constant",
    kind: "refactor.inline",
    works_on: :line

  alias Refactorex.Refactor.Constant

  def can_refactor?(%{node: {:@, _, [{id, _, nil}]} = node} = zipper, line) do
    cond do
      not AST.starts_at?(node, line) ->
        false

      is_nil(Constant.find_definition(zipper, id)) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(%{node: {:@, _, [{id, _, _}]}} = zipper, _) do
    {{_, _, [block]} = def, usages} = Constant.find_definition_and_usages(zipper, id)

    if length(usages) == 1 do
      zipper
      |> Z.replace(block)
      |> Z.top()
      |> Z.traverse(fn
        %{node: {:@, _, [^def]}} = zipper ->
          Z.remove(zipper)

        zipper ->
          zipper
      end)
    else
      Z.replace(zipper, block)
    end
  end
end
