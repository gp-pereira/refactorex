defmodule Refactorex.Refactor.Alias.ExpandAliases do
  use Refactorex.Refactor,
    title: "Expand aliases",
    kind: "refactor.rewrite",
    works_on: :selection

  alias Refactorex.Refactor.{
    Alias,
    Module
  }

  def can_refactor?(zipper, {:__block__, meta, [{a1, a2}]}),
    do: can_refactor?(zipper, {:__block__, meta, [a1, a2]})

  def can_refactor?(%{node: {_, _, aliases}} = zipper, {_, _, selected_aliases}) do
    cond do
      not AST.equal?(aliases, selected_aliases) ->
        false

      not Module.inside_one?(zipper) ->
        false

      not Alias.inside_declaration?(zipper) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(zipper, {:__block__, meta, [{a1, a2}]}),
    do: refactor(zipper, {:__block__, meta, [a1, a2]})

  def refactor(zipper, {id, _, aliases}) when id in ~w(__block__ {})a,
    do: Enum.reduce(aliases, zipper, &refactor(AST.go_to_node(&2, &1), nil))

  def refactor(zipper, _) do
    base_path = zipper |> Alias.expand_declaration() |> List.delete_at(-1)

    zipper
    |> Z.traverse_while(zipper, fn
      %{node: {:., _, _}} = zipper, refactored ->
        {:skip, zipper, refactored}

      %{node: {:__aliases__, _, _} = node} = zipper, refactored ->
        complete_path = base_path ++ Alias.expand_declaration(zipper)
        alias_ = {:alias, [], [{:__aliases__, [], complete_path}]}

        {
          :cont,
          zipper,
          refactored
          |> Alias.new_declaration(alias_)
          |> AST.go_to_node(node)
          |> remove_alias()
        }

      zipper, refactored ->
        {:cont, zipper, refactored}
    end)
    |> elem(1)
  end

  defp remove_alias(%{node: node} = zipper) do
    case parent = Z.up(zipper) do
      %{node: {:alias, _, [^node]}} ->
        Z.remove(parent)

      %{node: {{:., _, _}, _, [_single_alias]}} ->
        remove_alias(parent)

      %{node: {{:., _, _} = dot, meta, [_, _ | _] = aliases}} ->
        Z.replace(parent, {dot, meta, List.delete(aliases, node)})
    end
  end
end
