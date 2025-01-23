defmodule Refactorex.Refactor.Function.RenameFunction do
  use Refactorex.Refactor,
    title: "Rename function (current module only)",
    kind: "source",
    works_on: :selection

  alias Refactorex.Refactor.{
    Function,
    Module
  }

  defguardp inside_range(min_args, max_args, num_args)
            when min_args <= num_args and num_args <= max_args

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
    [definition | _] = _definitions = Function.find_definitions(zipper)
    {min_args, max_args} = Function.range_of_args(definition)

    zipper
    |> Module.go_to_scope()
    |> Z.traverse_while(fn
      %{node: {:|>, _, [_, {^name, meta, args}]}} = zipper
      when inside_range(min_args, max_args, length(args) + 1) ->
        {:cont,
         zipper
         |> Z.down()
         |> Z.right()
         |> Z.replace({placeholder(), meta, args})
         |> Z.up()}

      %{node: {:/, _, [{^name, meta, nil}, {:__block__, _, [num_args]}]}} = zipper
      when inside_range(min_args, max_args, num_args) ->
        {:cont,
         zipper
         |> Z.down()
         |> Z.replace({placeholder(), meta, nil})
         |> Z.up()}

      # zero arity function
      %{node: {^name, meta, args}} = zipper
      when (is_nil(args) or args == []) and min_args == 0 ->
        {:cont, Z.replace(zipper, {placeholder(), meta, args})}

      %{node: {^name, meta, args}} = zipper
      when inside_range(min_args, max_args, length(args)) ->
        {:cont, Z.replace(zipper, {placeholder(), meta, args})}

      zipper ->
        {:cont, zipper}
    end)
  end
end
