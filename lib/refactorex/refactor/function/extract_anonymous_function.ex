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

    name = available_function_name(zipper)

    zipper
    |> anonymous_to_function_call(name, args, closure_variables)
    |> add_private_function(name, args ++ closure_variables, body)
  end

  def refactor(%{node: {:fn, _, clauses}} = zipper, _) do
    outer_scope_variables = find_outer_scope_variables(zipper)

    closure_variables =
      clauses
      |> Enum.map(fn {:->, _, [args, body]} ->
        actual_args = Function.actual_args(args)

        Variable.find_variables(
          [args, body],
          reject: fn %{node: variable} ->
            Variable.member?(actual_args, variable) or
              not Variable.member?(outer_scope_variables, variable)
          end
        )
      end)
      |> List.flatten()
      |> Variable.remove_duplicates()

    # all clauses have the same number of args,
    # so we can just grab them from the first one
    {:->, _, [args, _]} = List.first(clauses)
    name = available_function_name(zipper)

    zipper
    |> anonymous_to_function_call(name, args, closure_variables)
    |> then(
      &Enum.reduce(clauses, &1, fn {:->, _, [args, body]}, zipper ->
        add_private_function(zipper, name, args ++ closure_variables, body)
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

  defp add_private_function(zipper, name, args, body) do
    Module.add_function(
      zipper,
      {:defp, [do: [], end: []],
       [
         case Function.unpin_args(args) do
           [{:when, _, [args, guard]} | other_args] ->
             {:when, [], [{name, [], [args | other_args]}, guard]}

           args ->
             {name, [], args}
         end,
         [{{:__block__, [], [:do]}, body}]
       ]}
    )
  end

  defp find_outer_scope_variables(%{node: node} = zipper) do
    zipper
    |> Z.find(:prev, fn
      {:defmodule, _, _} ->
        true

      node ->
        Function.definition?(node)
    end)
    |> Z.node()
    |> Variable.find_variables(reject: &(Sourceror.get_line(&1.node) >= Sourceror.get_line(node)))
  end

  defp available_function_name(zipper) do
    zipper
    |> Module.find_in_scope(&Function.definition?/1)
    |> Enum.reduce("extracted_function", fn
      {_, _, [{function_name, _, _}, _]}, current_name ->
        case Atom.to_string(function_name) do
          "extracted_function" ->
            "extracted_function1"

          "extracted_function" <> i ->
            "extracted_function#{String.to_integer(i) + 1}"

          _ ->
            current_name
        end
    end)
    |> String.to_atom()
  end

  defp already_extracted_function?({_, _, [{name, _, _} | _]}),
    do: String.starts_with?(Atom.to_string(name), "extracted_function")
end
