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
    statements = statements_to_inline(zipper)

    case Z.up(zipper) do
      %{node: {:__block__, _, _}} ->
        inline_statements(zipper, statements)

      _not_block when length(statements) > 1 ->
        extract_then_inline_statements(zipper, statements)

      _default ->
        inline_statements(zipper, statements)
    end
  end

  defp inline_statements(%{node: node} = zipper, statements) do
    zipper
    # just ensure enough space
    |> Variable.ExtractVariable.refactor(node)
    |> AST.go_to_node(node)
    |> Variable.InlineVariable.refactor(node)
    |> AST.go_to_node(node)
    |> inline_statements_before_node(statements)
    |> Z.remove()
  end

  defp extract_then_inline_statements(%{node: node} = zipper, statements) do
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
  defp invalid_parent?(%{node: {:&, _, _}}), do: true
  defp invalid_parent?(%{node: node}), do: Function.definition?(node)
end
