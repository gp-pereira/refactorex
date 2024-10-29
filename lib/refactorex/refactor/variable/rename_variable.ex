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

      match?(%{node: {:^, _, _}}, Z.up(zipper)) ->
        false

      not Variable.inside_declaration?(zipper) ->
        false

      true ->
        true
    end
  end

  def refactor(%{node: node} = zipper, {name, _, _} = selection) do
    case parent = Z.up(zipper) do
      %{node: {:when, _, [^node, _]}} ->
        Z.update(parent, &rename_usages(&1, name))

      %{node: {id, _, [^node, _]}} when id in ~w(def defp)a ->
        Z.update(parent, &rename_usages(&1, name))

      %{node: {:__block__, _, [[_ | _]]}} ->
        refactor(parent, selection)

      %{node: {:__block__, _, [{_, _}]}} ->
        refactor(parent, selection)

      %{node: {:__block__, meta, statements}} ->
        {before, [_ | rest]} = Enum.split_while(statements, &(&1 != node))

        Z.replace(
          parent,
          {:__block__, meta, before ++ [node | rename_usages(rest, name)]}
        )

      %{node: {:->, meta, [^node, _] = clause}} ->
        Z.replace(parent, {:->, meta, Enum.map(clause, &rename_usages(&1, name))})

      %{node: {id, meta, [^node, _] = clauses}} when id in ~w(case if)a ->
        Z.replace(parent, {id, meta, rename_usages(clauses, name)})

      %{node: {:=, meta, [^node, value]}} ->
        parent
        |> Z.replace({:=, meta, [rename_usages(node, name), value]})
        |> refactor(selection)

      %{} ->
        refactor(parent, selection)
    end
  end

  defp rename_usages(node, name),
    do: Variable.replace_usages_by_value(node, name, {placeholder(), [], nil})
end
