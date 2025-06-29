defmodule Refactorex.Refactor.Alias.InlineAlias do
  use Refactorex.Refactor,
    title: "Inline alias",
    kind: "refactor.inline",
    works_on: :selection

  alias Refactorex.Refactor.Alias

  def can_refactor?(%{node: {:__aliases__, _, _}} = zipper, selection) do
    cond do
      not Alias.contains_selection?(zipper, selection) ->
        false

      Alias.inside_declaration?(zipper) ->
        false

      is_nil(Alias.find_declaration(zipper)) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(%{node: {_, _, [_ | rest]}} = zipper, _),
    do: Z.replace(zipper, {:__aliases__, [], Alias.find_declaration(zipper) ++ rest})
end
