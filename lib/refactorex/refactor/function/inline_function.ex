defmodule Refactorex.Refactor.Function.InlineFunction do
  use Refactorex.Refactor,
    title: "Inline function",
    kind: "refactor.inline",
    works_on: :selection

  alias Refactorex.Refactor.{
    Function,
    Module,
    Variable
  }

  def can_refactor?(zipper, {:&, _, [body]}), do: can_refactor?(zipper, body)

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      not Module.inside_one?(zipper) ->
        false

      not Function.call?(node) ->
        false

      invalid_parent?(Z.up(zipper)) ->
        false

      Enum.empty?(Function.find_definitions(zipper)) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(zipper, _) do
    parent = Z.up(zipper)
    statements = statements_to_inline(zipper)

    cond do
      match?(%{node: {:&, _, [{:/, _, _}]}}, parent) ->
        parent
        |> Function.ExpandAnonymousFunction.refactor(parent.node)
        |> then(fn %{node: {:fn, _, [{:->, _, [_, body]}]}} = zipper ->
          zipper
          |> AST.go_to_node(body)
          |> refactor(body)
        end)
        |> maybe_collapse_anonymous_function()

      AST.up_until(zipper, &match?(%{node: {:&, _, _}}, &1)) ->
        zipper
        |> ensure_expanded_scope()
        |> refactor(zipper.node)
        |> maybe_collapse_anonymous_function()

      not match?(%{node: {:__block__, _, _}}, parent) and length(statements) > 1 ->
        extract_and_reassign_then_inline(zipper, statements)

      true ->
        zipper
        |> ensure_expanded_scope()
        |> inline_statements_before_node(statements)
        |> Z.remove()
    end
  end

  defp extract_and_reassign_then_inline(%{node: node} = zipper, statements) do
    {statements, [last_statement]} = Enum.split(statements, -1)

    zipper
    |> Variable.ExtractVariable.refactor(node)
    |> AST.go_to_node(node)
    |> Z.up()
    |> Z.update(fn {:=, _, [v, _]} -> {:=, [], [v, last_statement]} end)
    |> inline_statements_before_node(statements)
    |> AST.go_to_node(last_statement)
    |> Variable.InlineVariable.refactor(last_statement)
  end

  defp inline_statements_before_node(zipper, statements),
    do: Enum.reduce(statements, zipper, &Z.insert_left(&2, &1))

  defp statements_to_inline(%{node: {_, _, call_values}} = zipper) do
    case Function.find_definitions(zipper) do
      [{_, _, [{:when, _, _}, _]} = guarded_definition] ->
        merge_definitions_as_case_statement([guarded_definition], call_values)

      [{_, _, [{_, _, args}, _]} = definition] ->
        statements =
          case definition do
            {_, _, [_, [{_, {:__block__, _, statements}}]]} -> statements
            {_, _, [_, [{_, statement}]]} -> [statement]
          end

        if Enum.all?(args, &match?({_, _, nil}, &1)) do
          args
          |> Stream.zip(call_values)
          |> Enum.reduce(
            statements,
            fn {{arg_name, _, _}, call_value}, statements ->
              Variable.replace_usages_by_value(statements, arg_name, call_value)
            end
          )
        else
          [{:=, [], [{:{}, [], args}, {:{}, [], call_values}]} | statements]
        end

      definitions ->
        merge_definitions_as_case_statement(definitions, call_values)
    end
  end

  defp merge_definitions_as_case_statement(definitions, call_values) do
    [
      {:case, [do: [], end: []],
       [
         {:{}, [], call_values},
         [
           {{:__block__, [], [:do]},
            Enum.map(
              definitions,
              fn
                {_, _, [{:when, _, [{_, _, args}, guard]}, [{_, body}]]} ->
                  {:->, [], [[{:when, [], [{:{}, [], args}, guard]}], body]}

                {_, _, [{_, _, args}, [{_, body}]]} ->
                  {:->, [], [[{:{}, [], args}], body]}
              end
            )}
         ]
       ]}
    ]
  end

  defp invalid_parent?(%{node: {:|>, _, _}}), do: true
  defp invalid_parent?(%{node: node}), do: Function.definition?(node)

  defp ensure_expanded_scope(%{node: node} = zipper) do
    zipper
    |> Variable.ExtractVariable.refactor(node)
    |> Variable.InlineVariable.refactor(node)
  end

  defp maybe_collapse_anonymous_function(zipper) do
    zipper
    |> AST.up_until(&match?(%{node: {:fn, _, _}}, &1))
    |> then(
      &if Function.CollapseAnonymousFunction.can_refactor?(&1, &1.node),
        do: Function.CollapseAnonymousFunction.refactor(&1, &1.node),
        else: zipper
    )
  end
end
