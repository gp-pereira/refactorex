defmodule Refactorex.Refactor.Constant.InlineConstant do
  use Refactorex.Refactor,
    title: "Inline constant",
    kind: "refactor.inline",
    works_on: :selection

  def can_refactor?(%{node: {:@, _, [{_, _, nil}]} = node} = zipper, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      is_nil(find_definition(zipper)) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(zipper, _) do
    {:@, _, [{_, _, [block]}]} = find_definition(zipper)

    Z.replace(zipper, block)
  end

  defp find_definition(%{node: {:@, _, [{id, _, _}]}} = zipper) do
    zipper
    |> AST.find(&match?({:@, _, [{^id, _, u}]} when not is_nil(u), &1.node))
    |> List.first()
  end
end
