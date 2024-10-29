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
    %{node: {:=, _, [{name, _, _}, value]} = assignment} = parent = Z.up(zipper)

    case outer_scope = Z.up(parent) do
      %{node: {:->, meta, [args, ^assignment]}} ->
        Z.replace(outer_scope, {:->, meta, [args, value]})

      %{node: {{:__block__, meta, [tag]}, ^assignment}} when tag in ~w(do else)a ->
        Z.replace(outer_scope, {{:__block__, meta, [tag]}, value})

      %{node: {:__block__, meta, statements}} ->
        {before, [_ | rest]} = Enum.split_while(statements, &(&1 != assignment))

        Z.replace(
          outer_scope,
          if List.last(statements) == assignment do
            {:__block__, meta, before ++ [value]}
          else
            {:__block__, meta, before ++ Variable.replace_usages_by_value(rest, name, value)}
          end
        )

      %{node: {id, meta, [^assignment, clauses]}} when id in ~w(case if)a ->
        Z.replace(
          outer_scope,
          {id, meta, [value, Variable.replace_usages_by_value(clauses, name, value)]}
        )
    end
  end
end
