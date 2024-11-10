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
    case Function.find_definitions(zipper) do
      [{:def, _, [header, _]} = first_definition | _] = definitions ->
        definitions
        |> Enum.reduce(zipper, fn
          ^first_definition, zipper ->
            zipper
            |> copy_as_private_function(first_definition)
            |> redirect_to_private_function(first_definition)

          definition, zipper ->
            zipper
            |> copy_as_private_function(definition)
            |> AST.go_to_node(definition)
            |> Z.remove()
        end)
        |> rename_references(name, header)

      [{:defp, _, [header, _]} | _] ->
        rename_references(zipper, name, header)
    end
  end

  defp rename_references(zipper, name, {:when, _, [header, _]}),
    do: rename_references(zipper, name, header)

  defp rename_references(zipper, name, {_, _, function_args}) do
    zipper
    |> Z.top()
    |> Z.traverse_while(fn
      %{node: {:def, _, [{^name, _, args} | _]}} = zipper
      when length(function_args) == length(args) ->
        {:skip, zipper}

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

  defp copy_as_private_function(zipper, definition) do
    case definition do
      {_, _, [{:when, _, _} = args, [{_, body}]]} ->
        Function.new_private_function(zipper, placeholder(), args, body)

      {_, _, [{_, _, args}, [{_, body}]]} ->
        Function.new_private_function(zipper, placeholder(), args, body)
    end
  end

  defp redirect_to_private_function(zipper, definition) do
    case definition do
      {:def, _, [{:when, _, [{_, _, args} = header, _]} = guard, [{_, body}]]} ->
        zipper
        |> AST.go_to_node(guard)
        |> Z.replace(header)
        |> replace_body_by_redirect(body, args)

      {:def, _, [{_, _, args}, [{_, body}]]} ->
        replace_body_by_redirect(zipper, body, args)
    end
  end

  defp replace_body_by_redirect(zipper, body, args) do
    args_without_defaults =
      Enum.map(args, fn
        {:\\, _, [arg, _]} -> arg
        arg -> arg
      end)

    zipper
    |> AST.go_to_node(body)
    |> Z.replace({placeholder(), [], args_without_defaults})
  end
end
