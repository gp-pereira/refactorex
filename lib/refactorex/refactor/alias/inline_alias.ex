defmodule Refactorex.Refactor.Alias.InlineAlias do
  use Refactorex.Refactor,
    title: "Inline alias",
    kind: "refactor.inline",
    works_on: :selection

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      AST.inside?(zipper, &match?({:alias, _, _}, &1)) ->
        false

      is_nil(find_declaration(zipper)) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(%{node: {_, _, [_ | rest]}} = zipper, _),
    do: Z.replace(zipper, {:__aliases__, [], find_declaration(zipper) ++ rest})

  defp find_declaration(%{node: {_, _, [used_alias | _]}} = zipper) do
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
