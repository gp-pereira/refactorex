defmodule Refactorex.Refactor.Variable.ExtractVariable do
  use Refactorex.Refactor,
    title: "Extract variable",
    kind: "refactor.extract",
    works_on: :selection

  alias Refactorex.Refactor.{
    Function,
    IfElse,
    Variable
  }

  @variable_name "extracted_variable"

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      Variable.inside_declaration?(zipper) ->
        false

      match?(%{node: {:|>, _, [_, ^node]}}, Z.up(zipper)) ->
        false

      true ->
        true
    end
  end

  def refactor(%{node: node} = zipper, selection) do
    case parent = Z.up(zipper) do
      %{node: {:->, _, [args, ^node]}} ->
        Z.replace(
          parent,
          {:->, [], [args, extract_and_assign(parent, [node], node, selection)]}
        )

      %{node: {:__block__, meta, statements}} ->
        # if there is a closing tag, the block is probably a tuple
        if meta[:closing],
          do: refactor(parent, selection),
          else: Z.replace(parent, extract_and_assign(parent, statements, node, selection))

      %{node: {{:__block__, _, [_]}, ^node}} ->
        upper_structure = parent |> Z.up() |> Z.up()
        line = AST.get_start_line(upper_structure.node)

        cond do
          Function.UseRegularSyntax.can_refactor?(upper_structure, line) ->
            upper_structure
            |> Function.UseRegularSyntax.refactor(line)
            |> AST.go_to_node(node)
            |> refactor(selection)

          IfElse.UseRegularSyntax.can_refactor?(upper_structure, line) ->
            upper_structure
            |> IfElse.UseRegularSyntax.refactor(line)
            |> AST.go_to_node(node)
            |> refactor(selection)

          true ->
            Z.update(parent, fn {block, statement} ->
              {block, extract_and_assign(parent, [statement], statement, selection)}
            end)
        end

      # same pattern matching as ExpandAnonymousFunction.can_refactor?/2
      %{node: {:&, _, [body]}} when not is_number(body) ->
        {%{node: new_selection}, _} = Variable.turn_captures_into_variables(selection)

        parent
        |> Function.ExpandAnonymousFunction.refactor(parent.node)
        |> AST.go_to_node(new_selection)
        |> refactor(new_selection)

      _ ->
        refactor(parent, selection)
    end
  end

  defp extract_and_assign(zipper, statements, statement, selection) do
    {before, [_ | rest]} = Enum.split_while(statements, &(&1 != statement))

    variable = {next_available_name(zipper), [], nil}
    assignment = {:=, [], [variable, selection]}
    new_statement = replace_selection_by_variable(statement, selection, variable)

    {:__block__, [], before ++ [assignment, new_statement | rest]}
  end

  defp next_available_name(zipper) do
    zipper
    |> Z.top()
    |> Z.traverse(@variable_name, fn
      %{node: {id, _, nil}} = zipper, current_name when is_atom(id) ->
        {
          zipper,
          case Regex.run(~r/#{@variable_name}(\d*)/, Atom.to_string(id)) do
            [_, ""] ->
              "#{@variable_name}2"

            [_, i] ->
              "#{@variable_name}#{String.to_integer(i) + 1}"

            _ ->
              current_name
          end
        }

      zipper, current_name ->
        {zipper, current_name}
    end)
    |> elem(1)
    |> String.to_atom()
  end

  defp replace_selection_by_variable(statement, selection, variable) do
    if AST.equal?(statement, selection) do
      variable
    else
      statement
      |> Z.zip()
      |> AST.go_to_node(selection)
      |> Z.replace(variable)
      |> Z.top()
      |> Z.node()
    end
  end
end
