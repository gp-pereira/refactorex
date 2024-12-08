defmodule Refactorex.Refactor.Function.RenameFunction do
  use Refactorex.Refactor,
    title: "Rename function (current module only)",
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
    |> Module.go_to_scope()
    |> Z.traverse_while(fn
      %{node: {:|>, _, [_, {^name, meta, args}]}} = zipper
      when length(function_args) == length(args) + 1 ->
        {:cont,
         zipper
         |> Z.down()
         |> Z.right()
         |> Z.replace({placeholder(), meta, args})
         |> Z.up()}

      %{node: {:/, _, [{^name, meta, nil}, {:__block__, _, [num_args]}]}} = zipper
      when length(function_args) == num_args ->
        {:cont,
         zipper
         |> Z.down()
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
