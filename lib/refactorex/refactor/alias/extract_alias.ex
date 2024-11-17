defmodule Refactorex.Refactor.Alias.ExtractAlias do
  use Refactorex.Refactor,
    title: "Extract alias",
    kind: "refactor.extract",
    works_on: :selection

  alias Refactorex.Refactor.{
    Alias,
    Module
  }

  def can_refactor?(
        %{node: {:__aliases__, _, _}} = zipper,
        {:__aliases__, _, [_, _ | _] = selected_aliases} = selection
      ) do
    cond do
      not Alias.contains_selection?(zipper, selection) ->
        false

      not Module.inside_one?(zipper) ->
        false

      AST.inside?(zipper, &match?({:alias, _, _}, &1)) ->
        false

      name_conflict?(zipper, selected_aliases) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(zipper, {_, _, selected_aliases}) do
    refactored = extract_alias(zipper, selected_aliases)

    case Alias.find_declaration(refactored) do
      ^selected_aliases ->
        refactored

      nil ->
        Module.place_node(
          refactored,
          {:alias, [], [{:__aliases__, [], selected_aliases}]},
          &after_other_aliases/1
        )
    end
  end

  defp extract_alias(zipper, selected_aliases) do
    Z.update(zipper, fn {:__aliases__, meta, aliases} ->
      {:__aliases__, meta, drop_beginning(aliases, selected_aliases)}
    end)
  end

  defp drop_beginning([], _selected_aliases), do: []
  defp drop_beginning(aliases, []), do: aliases
  defp drop_beginning(aliases, [_last]), do: aliases

  defp drop_beginning([a | aliases], [a | selected_aliases]),
    do: drop_beginning(aliases, selected_aliases)

  defp drop_beginning(aliases, _), do: aliases

  defp after_other_aliases(nodes) do
    nodes
    |> Stream.with_index()
    |> Stream.map(fn
      {{id, _, _}, i} when id in ~w(use alias)a -> i + 1
      _ -> 0
    end)
    |> Enum.max()
  end

  defp name_conflict?(zipper, selected_aliases) do
    zipper
    |> extract_alias(selected_aliases)
    |> Alias.find_declaration()
    |> then(fn
      ^selected_aliases -> false
      nil -> false
      _other_declaration -> true
    end)
  end
end
