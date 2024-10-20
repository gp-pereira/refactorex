defmodule Refactorex.Refactor.Function.ExpandAnonymousFunction do
  use Refactorex.Refactor,
    title: "Expand anonymous function",
    kind: "refactor.rewrite",
    works_on: :selection

  alias Refactorex.Refactor.Variable

  def can_refactor?(%{node: {:&, _, [body]} = node}, selection)
      when not is_number(body),
      do: AST.equal?(node, selection)

  def can_refactor?(_, _), do: false

  def refactor(%{node: {:&, _, [{:/, _, [_, {_, _, [arg_count]}]}]}} = zipper, _) do
    args =
      if arg_count > 0,
        do: Enum.map(1..arg_count, &{String.to_atom("arg#{&1}"), [], nil}),
        else: []

    zipper
    |> Z.update(fn {:&, meta, [{:/, _, [{call, call_meta, _}, _]}]} ->
      {:fn, meta, [{:->, [], [args, {call, call_meta, args}]}]}
    end)
  end

  def refactor(%{node: {:&, _, [body]}} = zipper, _) do
    {%{node: body}, variables} = Variable.turn_captures_into_variables(body)
    Z.replace(zipper, {:fn, [], [{:->, [], [Enum.into(variables, []), body]}]})
  end
end
