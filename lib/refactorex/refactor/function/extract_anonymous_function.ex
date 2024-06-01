defmodule Refactorex.Refactor.Function.ExtractAnonymousFunction do
  use Refactorex.Refactor,
    title: "Extract anonymous function into private function",
    kind: "refactor.extract",
    works_on: :selection

  alias Refactorex.Refactor.{
    Function,
    Module,
    Variable
  }

  @function_name "extracted_function"

  def can_refactor?(%{node: {:fn, _, [{:->, _, [[] | _]}]}}, _), do: false

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      not Function.anonymous?(node) ->
        false

      not Module.inside_one?(zipper) ->
        false

      already_extracted_function?(node) ->
        :skip

      true ->
        true
    end
  end

  def refactor(%{node: {:&, _, [body]}} = zipper, _) do
    closure_variables = Variable.find_variables(body)

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

    name = Module.next_available_function_name(zipper, @function_name)

    zipper
    |> anonymous_to_function_call(name, args, closure_variables)
    |> Module.add_private_function(name, args ++ closure_variables, body)
  end

  def refactor(%{node: {:fn, _, clauses}} = zipper, _) do
    available_variables = Variable.find_available_variables(zipper)

    closure_variables =
      clauses
      |> Enum.map(fn {:->, _, [args, body]} ->
        actual_args = Function.actual_args(args)

        Variable.find_variables(
          [args, body],
          reject: fn %{node: variable} ->
            Variable.member?(actual_args, variable) or
              not Variable.member?(available_variables, variable)
          end
        )
      end)
      |> List.flatten()
      |> Variable.remove_duplicates()

    # all clauses have the same number of args,
    # so we can just grab them from the first one
    {:->, _, [args, _]} = List.first(clauses)
    name = Module.next_available_function_name(zipper, @function_name)

    zipper
    |> anonymous_to_function_call(name, args, closure_variables)
    |> then(
      &Enum.reduce(clauses, &1, fn {:->, _, [args, body]}, zipper ->
        Module.add_private_function(zipper, name, args ++ closure_variables, body)
      end)
    )
  end

  defp anonymous_to_function_call(zipper, name, args, closure_variables) do
    Z.update(zipper, fn _ ->
      {:&, [],
       [
         {name, [],
          1..length(args)
          |> Enum.map(&{:&, [], [&1]})
          |> Kernel.++(closure_variables)}
       ]}
    end)
  end

  defp already_extracted_function?({_, _, [{name, _, _} | _]})
       when is_atom(name),
       do: String.starts_with?(Atom.to_string(name), @function_name)

  defp already_extracted_function?(_), do: false
end
