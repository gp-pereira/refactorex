defmodule Refactorex.Refactor.Function.RenameFunction do
  use Refactorex.Refactor,
    title: "Rename function",
    kind: "source",
    works_on: :selection

  alias Refactorex.Refactor.{
    Function,
    Module
  }

  def can_refactor?(%{node: {name, meta, _}} = zipper, selection) do
    cond do
      not AST.equal?({name, meta, nil}, selection) ->
        false

      not Module.inside_one?(zipper) ->
        false

      Enum.empty?(Function.find_definitions(zipper)) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(%{node: {name, _, _}} = zipper, _) do
    [{_, _, [header, _]} | _] = Function.find_definitions(zipper)

    rename_references(zipper, name, header)
  end

  defp rename_references(zipper, name, {:when, _, [header, _]}),
    do: rename_references(zipper, name, header)

  defp rename_references(zipper, name, {_, _, function_args}) do
    zipper
    |> Z.top()
    |> Z.traverse_while(fn
      %{node: {:|>, _, [_, {^name, meta, args} = function]}} = zipper
      when length(function_args) == length(args) + 1 ->
        {:cont,
         zipper
         |> AST.go_to_node(function)
         |> Z.replace({placeholder(), meta, args})
         |> Z.up()}

      %{node: {:/, _, [{^name, meta, nil} = function, {:__block__, _, [num_args]}]}}
      when length(function_args) == num_args ->
        {:cont,
         zipper
         |> AST.go_to_node(function)
         |> Z.replace({placeholder(), meta, nil})
         |> Z.up()}

      %{node: {^name, meta, args}} = zipper
      when length(function_args) == length(args) ->
        {:cont, Z.replace(zipper, {placeholder(), meta, args})}

      zipper ->
        {:cont, zipper}
    end)
  end
end
