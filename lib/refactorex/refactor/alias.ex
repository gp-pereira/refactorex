defmodule Refactorex.Refactor.Alias do
  alias Sourceror.Zipper, as: Z
  alias Refactorex.Refactor.AST

  def contains_selection?(
        %{node: {:__aliases__, _, aliases} = node},
        {:__aliases__, _, selected_aliases} = selection
      ) do
    AST.starts_at?(node, AST.get_start_line(selection)) and
      same_beginning?(aliases, selected_aliases)
  end

  def contains_selection?(_, _), do: false

  defp same_beginning?(_aliases, []), do: true

  defp same_beginning?([a | aliases], [a | selected_aliases]),
    do: same_beginning?(aliases, selected_aliases)

  defp same_beginning?(_aliases, _selected_aliases), do: false

  def find_declaration(%{node: {_, _, [used_alias | _]}} = zipper) do
    zipper
    |> Z.top()
    |> Z.traverse(nil, fn
      %{node: {:alias, _, _} = node} = zipper, last_declaration ->
        if declaration = go_to_declaration(node, used_alias),
          do: {zipper, expand_declaration(declaration)},
          else: {zipper, last_declaration}

      zipper, declaration ->
        {zipper, declaration}
    end)
    |> elem(1)
  end

  defp go_to_declaration(node, used_alias) do
    node
    |> Z.zip()
    |> Z.find(fn
      {:alias, _, [_, opts]} ->
        Enum.any?(opts, &match?({{_, _, [:as]}, {_, _, [^used_alias]}}, &1))

      {:__aliases__, _, aliases} ->
        List.last(aliases) == used_alias

      _ ->
        false
    end)
  end

  defp expand_declaration(zipper, path \\ []) do
    case zipper do
      %{node: {:__aliases__, _, aliases}} ->
        expand_declaration(Z.up(zipper), aliases ++ path)

      %{node: {{:., _, [{:__aliases__, _, aliases}, _]}, _, _}} ->
        expand_declaration(Z.up(zipper), aliases ++ path)

      %{node: {:alias, _, [{:__aliases__, _, aliases} | _]}} ->
        aliases ++ (path -- aliases)

      _ ->
        path
    end
  end
end
