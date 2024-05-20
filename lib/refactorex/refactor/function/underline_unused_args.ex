defmodule Refactorex.Refactor.Function.UnderlineUnusedArgs do
  use Refactorex.Refactor,
    title: "Underline unused arguments",
    kind: "refactor",
    works_on: :line

  alias Refactorex.Refactor.{
    Function,
    Variable
  }

  def can_refactor?(%{node: node}, line) do
    cond do
      not (Function.definition?(node) or match?({:->, _, _}, node)) ->
        false

      not AST.starts_at?(node, line) ->
        false

      Enum.empty?(find_unused_args(node)) ->
        false

      true ->
        true
    end
  end

  def refactor(%{node: node} = zipper, _) do
    unused_args = find_unused_args(node)

    zipper
    |> Z.update(fn {id, meta, [args, body]} ->
      args
      |> Z.zip()
      |> Z.traverse(fn %{node: variable} = zipper ->
        if Variable.member?(unused_args, variable),
          do: underline_unused_arg(zipper, variable),
          else: zipper
      end)
      |> Z.node()
      |> then(&{id, meta, [&1, body]})
    end)
  end

  defp find_unused_args({id, meta, [{:when, _, [args, guard]}, body]}),
    do: find_unused_args({id, meta, [args, [guard, body]]})

  defp find_unused_args({_, _, [args, body]}) do
    used_variables = Variable.find_variables(body)
    actual_args = Function.actual_args(args)

    Enum.filter(actual_args, fn {arg_id, _, _} = arg ->
      cond do
        arg_id |> Atom.to_string() |> String.starts_with?("_") ->
          false

        Enum.count(actual_args, fn {id, _, _} -> id == arg_id end) > 1 ->
          false

        Variable.member?(used_variables, arg) ->
          false

        true ->
          true
      end
    end)
  end

  defp underline_unused_arg(zipper, {id, _, nil}),
    do: Z.update(zipper, fn _ -> {String.to_atom("_#{id}"), [], nil} end)
end
