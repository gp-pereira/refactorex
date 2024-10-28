defmodule Refactorex.Refactor.Variable.InlineVariable do
  use Refactorex.Refactor,
    title: "Inline variable",
    kind: "refactor.inline",
    works_on: :selection

  alias Refactorex.Refactor.{
    Function,
    Variable
  }

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
          if(List.last(statements) == assignment,
            do: {:__block__, meta, before ++ [value]},
            else: {:__block__, meta, before ++ replace_usages_by_value(rest, name, value)}
          )
        )

      %{node: {id, meta, [^assignment, clauses]}} when id in ~w(case if)a ->
        Z.replace(
          outer_scope,
          {id, meta, [value, replace_usages_by_value(clauses, name, value)]}
        )
    end
  end

  defp replace_usages_by_value(statements, name, value) do
    statements
    |> Z.zip()
    |> Z.traverse_while(fn
      %{node: {:->, _, [args, _]}} = zipper ->
        if was_name_reassigned?(args, name),
          do: {:skip, zipper},
          else: {:cont, zipper}

      %{node: {:=, meta, [args, new_value]}} = zipper ->
        if was_name_reassigned?(args, name),
          do: {
            :skip,
            zipper
            |> Z.replace({
              :=,
              meta,
              [args, replace_usages_by_value(new_value, name, value)]
            })
            # go up to skip traversing right siblings
            |> Z.up()
          },
          else: {:cont, zipper}

      %{node: {^name, _, nil}} = zipper ->
        {:cont, Z.replace(zipper, value)}

      zipper ->
        {:cont, zipper}
    end)
    |> Z.node()
  end

  defp was_name_reassigned?(args, name) do
    args
    |> Function.actual_args()
    |> Variable.member?({name, [], nil})
  end
end
