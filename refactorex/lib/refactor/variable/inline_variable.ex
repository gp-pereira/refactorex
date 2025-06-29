defmodule Refactorex.Refactor.Variable.InlineVariable do
  use Refactorex.Refactor,
    title: "Inline variable",
    kind: "refactor.inline",
    works_on: :selection

  alias Refactorex.Refactor.Variable

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      not match?(%{node: {:=, _, [^node, _]}}, Z.up(zipper)) ->
        false

      # inside another assignment
      match?(%{node: {:=, _, _}}, AST.up(zipper, 2)) ->
        false

      not Variable.at_one?(zipper) ->
        false

      true ->
        true
    end
  end

  def refactor(zipper, _) do
    %{node: {:=, _, [declaration, value]}} = parent = Z.up(zipper)
    [_ | usages] = Variable.find_all_references(zipper, declaration)

    if(replace_assignment_by_value?(parent),
      do: Z.replace(parent, value),
      else: Z.remove(parent)
    )
    |> AST.replace_nodes(usages, value)
    |> AST.go_to_node(value)
  end

  defp replace_assignment_by_value?(%{node: assignment} = zipper) do
    case Z.up(zipper) do
      %{node: {:->, _, [_, ^assignment]}} ->
        true

      %{node: {id, _, [^assignment, _]}} when id in ~w(case if)a ->
        true

      %{node: {{:__block__, _, [tag]}, ^assignment}} when tag in ~w(do else)a ->
        true

      %{node: {:__block__, _, statements}} ->
        List.last(statements) == assignment

      _ ->
        false
    end
  end
end
