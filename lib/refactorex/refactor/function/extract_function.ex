defmodule Refactorex.Refactor.Function.ExtractFunction do
  use Refactorex.Refactor,
    title: "Extract function",
    kind: "refactor.extract",
    works_on: :selection

  alias Refactorex.Refactor.{
    Function,
    Module,
    Pipeline,
    Variable
  }

  @function_name "extracted_function"

  def can_refactor?(%{node: {id, _, _}}, _)
      when id in ~w(@ & <- alias __aliases__)a,
      do: :skip

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not Module.inside_one?(zipper) ->
        false

      Variable.inside_declaration?(zipper) ->
        false

      AST.equal?(node, selection) ->
        true

      Pipeline.starts_at?(selection, node) ->
        true

      true ->
        false
    end
  end

  def refactor(%{node: node} = zipper, selection) do
    name = Function.next_available_function_name(zipper, @function_name)
    args = find_function_args(zipper, selection)

    if Pipeline.starts_at?(selection, node) do
      %{node: {:|>, _, [before, _]}} = Z.up(zipper)

      zipper
      |> Pipeline.go_to_top(selection)
      |> Z.replace({:|>, [], [before, {name, [], args}]})
      |> Function.new_private_function(
        name,
        [{:arg1, [], nil} | args],
        Pipeline.update_start(selection, &{:|>, [], [{:arg1, [], nil}, &1]})
      )
    else
      zipper
      |> Z.replace({name, [], args})
      |> Function.new_private_function(name, args, selection)
    end
  end

  defp find_function_args(zipper, selection) do
    available_variables = Variable.find_available_variables(zipper)

    selection
    |> Variable.list_unique_variables()
    |> Enum.reject(&(not Variable.member?(available_variables, &1)))
  end
end
