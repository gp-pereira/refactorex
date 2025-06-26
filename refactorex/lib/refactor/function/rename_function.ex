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

  defmacrop module_call(name, meta, args) do
    quote do: {{:., _, [{:__MODULE__, _, nil}, unquote(name)]}, unquote(meta), unquote(args)}
  end

  def can_refactor?(%{node: module_call(name, meta, args)} = zipper, selection) do
    zipper
    |> Z.replace({name, meta, args})
    |> can_refactor?(selection)
  end

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

  def refactor(%{node: module_call(_, _, _)} = zipper, selection) do
    zipper
    |> replace_module_calls()
    |> refactor(selection)
  end

  def refactor(%{node: {name, _, _}} = zipper, _) do
    [definition | _] = Function.find_definitions(zipper)
    {min_args, max_args} = Function.range_of_args(definition)

    zipper
    |> Module.go_to_scope()
    |> replace_module_calls()
    |> Z.traverse_while(fn
      %{node: {:|>, _, [_, {^name, meta, args}]}} = zipper ->
        {:skip,
         if inside_range(min_args, max_args, length(args) + 1) do
           zipper
           |> Z.down()
           |> Z.right()
           |> Z.replace({placeholder(), meta, args})
           |> Z.up()
         else
           zipper
         end}

      %{node: {:/, _, [{^name, meta, args}, {:__block__, _, [num_args]}]}} = zipper ->
        {:skip,
         if inside_range(min_args, max_args, num_args) do
           zipper
           |> Z.down()
           |> Z.replace({placeholder(), meta, args})
           |> Z.up()
         else
           zipper
         end}

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
    |> bring_module_calls_back()
  end

  def replace_module_calls(zipper) do
    Z.traverse(zipper, fn
      %{node: module_call(name, meta, args)} = zipper ->
        Z.replace(zipper, {name, Keyword.put(meta, :replaced, true), args})

      zipper ->
        zipper
    end)
  end

  def bring_module_calls_back(zipper) do
    Z.traverse(zipper, fn
      %{node: {name, meta, args}} = zipper ->
        if meta[:replaced],
          do: Z.replace(zipper, {{:., [], [{:__MODULE__, [], nil}, name]}, meta, args}),
          else: zipper

      zipper ->
        zipper
    end)
  end
end
