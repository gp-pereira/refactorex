defmodule Refactorex.Refactor.Variable.ExtractVariable do
  use Refactorex.Refactor,
    title: "Extract variable",
    kind: "refactor.extract",
    works_on: :selection

  alias Refactorex.NameCache

  alias Refactorex.Refactor.{
    Function,
    IfElse,
    Variable
  }

  @variable_name "extracted_variable"

  def can_refactor?(%{node: {id, _, _}}, _)
      when id in ~w(alias __aliases__)a,
      do: false

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
        parent
        |> Z.replace({:->, [], [args, extract_and_assign(parent, [node], node, selection)]})
        |> AST.go_to_node(selection)

      # selection is inside a COND clause
      %{node: {:->, _, [^node, _]}} ->
        %{node: {:cond, _, _}} = zipper_at_cond = AST.up(parent, 4)
        refactor(zipper_at_cond, selection)

      %{node: {:__block__, meta, statements}} ->
        # if there is a closing tag, the block is probably a tuple
        if meta[:closing] do
          refactor(parent, selection)
        else
          parent
          |> Z.replace(extract_and_assign(parent, statements, node, selection))
          |> AST.go_to_node(selection)
        end

      %{node: {{:__block__, _, [tag]}, ^node}} when tag in ~w(do else)a ->
        upper_structure = AST.up(parent, 2)
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
        |> AST.go_to_node(selection)

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
    NameCache.consume_name_or(fn ->
      zipper
      |> Z.top()
      |> Z.traverse([0], fn
        %{node: {id, _, nil}} = zipper, used_numbers when is_atom(id) ->
          {
            zipper,
            case Regex.run(~r/#{@variable_name}(\d*)/, Atom.to_string(id)) do
              [_, ""] ->
                [1 | used_numbers]

              [_, i] ->
                [String.to_integer(i) | used_numbers]

              _ ->
                used_numbers
            end
          }

        zipper, used_numbers ->
          {zipper, used_numbers}
      end)
      |> elem(1)
      |> Enum.max()
      |> then(&"#{@variable_name}#{if &1 == 0, do: "", else: &1 + 1}")
      |> String.to_atom()
    end)
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
