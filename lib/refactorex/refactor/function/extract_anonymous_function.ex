defmodule Refactorex.Refactor.Function.ExtractAnonymousFunction do
  use Refactorex.Refactor,
    title: "Extract anonymous function into private function",
    kind: "refactor.extract"

  alias Refactorex.Refactor.{
    Function,
    Module,
    Variable
  }

  def can_refactor?(%{node: node} = zipper, range) do
    cond do
      not Function.anonymous?(node) ->
        false

      not Module.inside_one?(zipper) ->
        :skip

      not SelectionRange.selects_this_node?(range, node, column_delta: 2) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(%{node: {:&, _, [body]}} = zipper) do
    deps = Variable.find_used_variables(body)

    # find &{i} usages and replace them with arg{i}
    {%{node: body}, args} =
      body
      |> Z.zip()
      |> Z.traverse_while([], fn
        %{node: {:&, _, [i]}} = zipper, args when is_number(i) ->
          arg = {String.to_atom("arg#{i}"), [], nil}
          {:cont, Z.update(zipper, fn _ -> arg end), args ++ [arg]}

        zipper, args ->
          {:cont, zipper, args}
      end)

    do_refactor(zipper, args, deps, body)
  end

  def refactor(%{node: {:fn, _, [{:->, _, [args, body]}]}} = zipper) do
    deps = Variable.find_used_variables(body, ignore: args)
    do_refactor(zipper, args, deps, body)
  end

  defp do_refactor(zipper, args, deps, body) do
    zipper
    |> Z.update(fn _ ->
      {:&, [],
       [
         {:extracted_function, [],
          args
          |> Stream.with_index()
          |> Enum.map(fn {_, i} -> {:&, [], [i + 1]} end)
          |> Kernel.++(deps)}
       ]}
    end)
    |> Module.add_function(
      {:defp, [do: [], end: []],
       [
         {:extracted_function, [], args ++ deps},
         [{{:__block__, [], [:do]}, body}]
       ]}
    )
  end
end
