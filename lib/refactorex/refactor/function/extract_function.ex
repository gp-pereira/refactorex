defmodule Refactorex.Refactor.Function.ExtractFunction do
  use Refactorex.Refactor,
    title: "Extract private function",
    kind: "refactor.extract",
    works_on: :selection

  alias Refactorex.Refactor.{
    AST,
    Module,
    Pipeline,
    Variable
  }

  def can_refactor?(%{node: {id, _, _}}, _)
      when id in ~w(@ & <-)a,
      do: false

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not Module.inside_one?(zipper) ->
        false

      AST.equal?(node, selection) ->
        true

      Pipeline.starts_at?(selection, node) ->
        true

      block_of_siblings?(zipper, selection) ->
        true

      true ->
        false
    end
  end

  def refactor(%{node: node} = zipper, selection) do
    name = Module.next_available_function_name(zipper, "extracted_function")
    args = find_function_args(zipper, selection)

    cond do
      Pipeline.starts_at?(selection, node) ->
        %{node: {:|>, _, [before, _]}} = Z.up(zipper)

        zipper
        |> Pipeline.go_to_top(selection)
        |> Z.replace({:|>, [], [before, {name, [], args}]})
        |> Module.add_private_function(
          name,
          [{:arg1, [], nil} | args],
          Pipeline.update_start(selection, &{:|>, [], [{:arg1, [], nil}, &1]})
        )

      block_of_siblings?(zipper, selection) ->
        zipper
        |> remove_siblings(selection)
        # go back to where it was
        |> Z.find(:prev, &(&1 == node))
        |> extract_and_add_function(name, args, selection)

      true ->
        extract_and_add_function(zipper, name, args, selection)
    end
  end

  defp block_of_siblings?(zipper, {:__block__, _, children}),
    do: block_of_siblings?(zipper, children)

  defp block_of_siblings?(_, []), do: true

  defp block_of_siblings?(nil, _), do: false

  defp block_of_siblings?(%{node: node} = zipper, [child | rest]) do
    if AST.equal?(node, child),
      do: block_of_siblings?(Z.right(zipper), rest),
      else: false
  end

  defp block_of_siblings?(_, _), do: false

  defp remove_siblings(zipper, {:__block__, _, children} = block) do
    case right = Z.right(zipper) do
      nil ->
        zipper

      %{node: node} ->
        if Enum.any?(children, &AST.equal?(&1, node)) do
          right
          |> remove_siblings(block)
          |> Z.remove()
        else
          zipper
        end
    end
  end

  defp find_function_args(zipper, selection) do
    available_variables = Variable.find_available_variables(zipper)

    Variable.find_variables(
      selection,
      reject: &(not Variable.member?(available_variables, &1.node))
    )
  end

  defp extract_and_add_function(zipper, name, args, selection) do
    {call, body} = maybe_fix_assignment(name, args, selection)

    zipper
    |> Z.replace(call)
    |> Module.add_private_function(name, args, body)
  end

  defp maybe_fix_assignment(name, args, {:__block__, meta, children} = block) do
    case List.last(children) do
      {:=, _, [assignee, assignment]} ->
        {
          {:=, [], [assignee, {name, [], args}]},
          {:__block__, meta, List.replace_at(children, -1, assignment)}
        }

      _ ->
        {{name, [], args}, block}
    end
  end

  defp maybe_fix_assignment(name, args, {:=, meta, [assignee, assignment]}),
    do: {{:=, meta, [assignee, {name, [], args}]}, assignment}

  defp maybe_fix_assignment(name, args, selection),
    do: {{name, [], args}, selection}
end
