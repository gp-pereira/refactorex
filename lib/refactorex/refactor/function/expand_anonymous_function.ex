defmodule Refactorex.Refactor.Function.ExpandAnonymousFunction do
  use Refactorex.Refactor,
    title: "Extract anonymous function",
    kind: "refactor.rewrite",
    works_on: :selection

  def can_refactor?(%{node: {:&, _, [_ | _]} = node}, selection),
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
    # find &{i} usages and replace them with arg{i}
    {%{node: body}, args} =
      body
      |> Z.zip()
      |> Z.traverse_while(MapSet.new(), fn
        %{node: {:&, _, [i]}} = zipper, args when is_number(i) ->
          arg = {String.to_atom("arg#{i}"), [], nil}
          {:cont, Z.update(zipper, fn _ -> arg end), MapSet.put(args, arg)}

        zipper, args ->
          {:cont, zipper, args}
      end)
      |> then(fn {zipper, args} -> {zipper, Enum.into(args, [])} end)

    zipper
    |> Z.update(fn {:&, meta, _} -> {:fn, meta, [{:->, [], [args, body]}]} end)
  end
end
