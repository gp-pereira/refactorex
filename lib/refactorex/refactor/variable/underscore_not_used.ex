defmodule Refactorex.Refactor.Variable.UnderscoreNotUsed do
  use Refactorex.Refactor,
    title: "Underscore variables not used",
    kind: "quickfix",
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
    |> Z.update(fn {id, meta, [header, body]} ->
      header
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

  defp find_unused_args({_, _, [{:when, _, [{_, _, args}, guard]}, body]}),
    do: find_unused_args(args, [body, guard])

  defp find_unused_args({_, _, [{_, _, args}, body]}),
    do: find_unused_args(args, body)

  defp find_unused_args({:->, _, [args, body]}),
    do: find_unused_args(args, body)

  defp find_unused_args(args, body) do
    used_variables = Variable.list_unique_variables(body)
    unpinned_args = Variable.list_unpinned_variables(args)

    Enum.filter(unpinned_args, fn {arg_id, _, _} = arg ->
      cond do
        arg_id |> Atom.to_string() |> String.starts_with?("_") ->
          false

        Enum.count(unpinned_args, fn {id, _, _} -> id == arg_id end) > 1 ->
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
