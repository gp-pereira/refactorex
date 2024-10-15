defmodule Refactorex.Refactor.Constant.InlineConstant do
  use Refactorex.Refactor,
    title: "Inline constant",
    kind: "refactor.inline",
    works_on: :line

  def can_refactor?(%{node: {:@, _, [{_, _, nil}]} = node} = zipper, line) do
    cond do
      not AST.starts_at?(node, line) ->
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

    if count_usages(zipper) > 1 do
      Z.replace(zipper, block)
    else
      zipper
      |> Z.replace(block)
      |> Z.top()
      |> Z.traverse(fn
        %{node: ^def} = zipper ->
          Z.remove(zipper)

        zipper ->
          zipper
      end)
    end
  end

  def find_definition(%{node: {:@, _, [{id, _, _}]}} = zipper) do
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
