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
    {:@, _, [{_, _, [block]}]} = def = find_definition(zipper)

    zipper
    |> Z.replace(block)
    |> then(
      &if count_usages(zipper) == 1,
        do: &1 |> AST.go_to_node(def) |> Z.remove(),
        else: &1
    )
  end

  defp find_definition(%{node: {:@, _, [{id, _, _}]}} = zipper) do
    zipper
    |> AST.find(&match?({:@, _, [{^id, _, u}]} when not is_nil(u), &1))
    |> List.first()
  end

  defp count_usages(%{node: {:@, _, [{id, _, _}]}} = zipper) do
    zipper
    |> AST.find(&match?({:@, _, [{^id, _, nil}]}, &1))
    |> length()
  end
end
