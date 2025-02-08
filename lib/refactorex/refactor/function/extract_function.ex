defmodule Refactorex.Refactor.Function.ExtractFunction do
  use Refactorex.Refactor,
    title: "Extract function",
    kind: "refactor.extract",
    works_on: :selection

  alias Refactorex.Refactor.{
    Dataflow,
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
    args = Dataflow.outer_variables(selection)
    new_arg = {:arg1, [], nil}

    cond do
      Pipeline.starts_at?(selection, node) ->
        %{node: {:|>, _, [before, _]}} = Z.up(zipper)

        zipper
        |> Pipeline.go_to_top(selection)
        |> Z.replace({:|>, [], [before, {name, [], args}]})
        |> Function.new_private_function(
          name,
          [new_arg | args],
          Pipeline.update_start(selection, &{:|>, [], [new_arg, &1]})
        )

      match?(%{node: {:|>, _, [_, ^node]}}, Z.up(zipper)) ->
        zipper
        |> Z.replace({name, [], args})
        |> Function.new_private_function(
          name,
          [new_arg | args],
          {:|>, [], [new_arg, selection]}
        )

      true ->
        zipper
        |> Z.replace({name, [], args})
        |> Function.new_private_function(name, args, selection)
    end
  end
end
