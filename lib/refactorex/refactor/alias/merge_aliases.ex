defmodule Refactorex.Refactor.Alias.MergeAliases do
  use Refactorex.Refactor,
    title: "Merge aliases",
    kind: "refactor.rewrite",
    works_on: :selection

  alias Refactorex.Refactor.Alias

  def can_refactor?(zipper, {:__block__, meta, [{s1, s2}]}),
    do: can_refactor?(zipper, {:__block__, meta, [s1, s2]})

  def can_refactor?(zipper, {:__block__, _, selected_aliases}) do
    cond do
      group_mergeable_aliases(selected_aliases) == [] ->
        :skip

      not Enum.all?(selected_aliases, &AST.go_to_node(zipper, &1)) ->
        :skip

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: :skip

  def refactor(zipper, {:__block__, meta, [{s1, s2}]}),
    do: refactor(zipper, {:__block__, meta, [s1, s2]})

  def refactor(zipper, {_, _, aliases}) do
    aliases
    |> group_mergeable_aliases()
    |> Enum.reduce(zipper, fn [alias_ | duplicated] = aliases, zipper ->
      duplicated
      |> Enum.reduce(zipper, &Z.remove(AST.go_to_node(&2, &1)))
      |> AST.go_to_node(alias_)
      |> Z.replace({:alias, [], merge_aliases(aliases)})
    end)
  end

  defp group_mergeable_aliases(selected_aliases) do
    selected_aliases
    |> Stream.filter(fn
      {:alias, _, [{:__aliases__, _, [_root]} | _]} ->
        false

      {:alias, _, [_, opts]} ->
        not Enum.any?(opts, &match?({{_, _, [:as]}, _}, &1))

      {:alias, _, _} ->
        true

      _ ->
        false
    end)
    |> Enum.group_by(fn
      {:alias, _, [{{:., _, [{_, _, [root | _]}, _]}, _, _} | _]} ->
        root

      {:alias, _, [{:__aliases__, _, [root | _]} | _]} ->
        root
    end)
    |> Map.values()
    |> Enum.reject(&(length(&1) < 2))
  end

  defp merge_aliases(aliases) do
    aliases
    |> Z.zip()
    |> Z.traverse_while([], fn
      %{node: {:., _, _}} = zipper, declarations ->
        {:skip, zipper, declarations}

      %{node: {:__aliases__, _, _}} = zipper, declarations ->
        {:cont, zipper, [Alias.expand_declaration(zipper) | declarations]}

      zipper, declarations ->
        {:cont, zipper, declarations}
    end)
    |> elem(1)
    |> Enum.uniq()
    |> Enum.sort()
    |> merge_declarations()
  end

  defp merge_declarations([[root | _] | _] = declarations, path \\ []) do
    cond do
      length(declarations) == 1 ->
        [{:__aliases__, [], List.first(declarations)}]

      Enum.any?(declarations, &(length(&1) == 1)) ->
        {single, multiple} = Enum.split_with(declarations, &(length(&1) == 1))

        [
          {
            {:., [], [{:__aliases__, [], path}, :{}]},
            [newlines: 1],
            Enum.map(single, &{:__aliases__, [], &1}) ++
              if(length(multiple) > 0,
                do: merge_declarations(multiple, []),
                else: []
              )
          }
        ]

      Enum.all?(declarations, &List.starts_with?(&1, [root])) ->
        declarations
        |> Enum.map(&List.delete_at(&1, 0))
        |> merge_declarations(path ++ [root])

      true ->
        declarations
        |> Enum.group_by(&List.first/1)
        |> Map.values()
        |> Enum.map(&merge_declarations(&1, path))
        |> List.flatten()
    end
  end
end
