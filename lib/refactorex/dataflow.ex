defmodule Refactorex.Dataflow do
  alias Sourceror.Zipper, as: Z

  defguard is_variable(node)
           when is_tuple(node) and
                  tuple_size(node) == 3 and
                  is_atom(elem(node, 0)) and
                  elem(node, 0) != :binary and
                  is_nil(elem(node, 2))

  defstruct commands: [],
            variables: []

  def analyze(node) do
    %__MODULE__{}
    |> recursive_analyze(node)
    |> Map.get(:variables)
    |> Enum.map(&{&1.declaration, &1.usages})
    |> Map.new()
  end

  def outer_variables(node) do
    %__MODULE__{}
    |> recursive_analyze(node)
    |> Map.get(:commands)
    |> Stream.map(fn {:use, variable} -> variable end)
    |> Enum.reverse()
    |> Enum.uniq_by(fn {name, _, _} -> name end)
  end

  defp recursive_analyze(dataflow, zipper) do
    case zipper do
      {id, _, [{_, _, header}, body]} when id in ~w(def defp)a ->
        analyze_sealed_scope(dataflow, header, body)

      {id, _, [{:when, _, [header, body]}]} when id in ~w(defguard defguardp)a ->
        analyze_sealed_scope(dataflow, header, body)

      {id, _, [condition, clauses]} when id in ~w(if unless)a ->
        %__MODULE__{}
        |> recursive_analyze(condition)
        |> then(fn if_dataflow ->
          Enum.reduce(clauses, if_dataflow, &analyze_scope(&2, &1))
        end)
        |> close_scope(dataflow)

      {:cond, _, [[{_, clauses}]]} ->
        Enum.reduce(clauses, dataflow, fn
          {:->, _, clause}, dataflow -> analyze_scope(dataflow, clause)
        end)

      {:try, _, [[body | catches]]} ->
        %__MODULE__{}
        |> analyze_scope(body)
        |> recursive_analyze(catches)
        |> close_scope(dataflow)

      {:case, _, expression_and_clauses} ->
        analyze_compound_scope(dataflow, expression_and_clauses, [])

      {:with, _, children} ->
        {
          statements,
          [[body | catches]]
        } = Enum.split_while(children, &match?({:<-, _, _}, &1))

        dataflow
        |> analyze_compound_scope(statements, body)
        |> recursive_analyze(catches)

      {:for, _, children} ->
        {statements, body} = Enum.split_while(children, &match?({_, _, _}, &1))
        analyze_compound_scope(dataflow, statements, body)

      {{:__block__, _, [:do]}, block} ->
        analyze_scope(dataflow, block)

      {:test, _, [_, {:%{}, _, setup}, scope]} ->
        analyze_sealed_scope(dataflow, setup, scope)

      {:test, _, scope} ->
        analyze_sealed_scope(dataflow, scope)

      {:->, _, [[{:when, _, [left, guard]}], right]} ->
        analyze_scope(dataflow, left, [guard, right])

      {:->, _, [left, right]} ->
        analyze_scope(dataflow, left, right)

      {:<-, _, [{:when, _, [left, guard]}, right]} ->
        dataflow
        |> recursive_analyze(right)
        |> add_commands(gen_commands(left))
        |> recursive_analyze(guard)

      {id, _, [left, right]} when id in ~w(= <-)a ->
        dataflow
        |> recursive_analyze(right)
        |> add_commands(gen_commands(left))

      {:@, _, [node]} when is_variable(node) ->
        dataflow

      node when is_variable(node) ->
        add_commands(dataflow, [{:use, node}])

      node ->
        if children = Z.children(node),
          do: Enum.reduce(children, dataflow, &recursive_analyze(&2, &1)),
          else: dataflow
    end
  end

  defp analyze_compound_scope(dataflow, before_statements, scope) do
    before_statements
    |> Enum.reduce(%__MODULE__{}, &recursive_analyze(&2, &1))
    |> analyze_scope(scope)
    |> close_scope(dataflow)
  end

  defp analyze_sealed_scope(dataflow, maybe_declarations \\ [], scope) do
    dataflow
    |> analyze_scope(maybe_declarations, scope)
    # don't let commands leak to outer scope
    |> Map.put(:commands, dataflow.commands)
  end

  defp analyze_scope(dataflow, maybe_declarations \\ [], scope) do
    %__MODULE__{}
    |> add_commands(gen_commands(maybe_declarations))
    |> recursive_analyze(scope)
    |> close_scope(dataflow)
  end

  defp close_scope(scope_dataflow, dataflow) do
    %{commands: scoped_commands, variables: inner_scoped_variables} = scope_dataflow

    # process all remaining commands inside the current scope into a new dataflow
    %{commands: unused_commands, variables: scoped_variables} =
      scoped_commands
      |> Enum.reverse()
      |> Enum.reduce(%__MODULE__{}, &process_command/2)

    %{
      dataflow
      | # unused commands (usages) are passed to the outer scope
        commands: unused_commands ++ dataflow.commands,
        variables: scoped_variables ++ inner_scoped_variables ++ dataflow.variables
    }
  end

  defp process_command(command, %{variables: variables} = scoped_dataflow) do
    case command do
      {:gen, {name, _, _} = variable} ->
        variable = %{name: name, declaration: variable, usages: []}

        %{scoped_dataflow | variables: [variable | variables]}

      {:use, {name, _, _} = variable} ->
        if i = Enum.find_index(variables, &(&1.name == name)) do
          variables = update_in(variables, [Access.at(i), :usages], &[variable | &1])

          %{scoped_dataflow | variables: variables}
        else
          add_commands(scoped_dataflow, [command])
        end
    end
  end

  defp gen_commands(node) do
    node
    |> Z.zip()
    |> Z.traverse_while([], fn
      %{node: {:@, _, [node]}} = zipper, commands when is_variable(node) ->
        {:skip, zipper, commands}

      %{node: {:^, _, [node]}} = zipper, commands when is_variable(node) ->
        {:skip, zipper, [{:use, node} | commands]}

      %{node: {name, _, _} = node} = zipper, commands when is_variable(node) ->
        command =
          if Enum.any?(commands, fn {_, {n, _, _}} -> n == name end),
            do: {:use, node},
            else: {:gen, node}

        {:cont, zipper, [command | commands]}

      zipper, commands ->
        {:cont, zipper, commands}
    end)
    |> elem(1)
  end

  defp add_commands(dataflow, commands),
    do: %{dataflow | commands: commands ++ dataflow.commands}
end
