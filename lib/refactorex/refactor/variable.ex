defmodule Refactorex.Refactor.Variable do
  alias Refactorex.Refactor.AST
  alias Sourceror.Zipper, as: Z

  def at_one?(%{node: {name, _, nil}} = zipper) do
    cond do
      not is_atom(name) or name in ~w(binary)a ->
        false

      match?(%{node: {:@, _, _}}, Z.up(zipper)) ->
        false

      true ->
        true
    end
  end

  def at_one?(_zipper), do: false

  def find_variables(node) do
    node
    |> Z.zip()
    |> Z.traverse_while([], fn
      %{node: node} = zipper, variables ->
        if at_one?(zipper),
          do: {:cont, zipper, variables ++ [node]},
          else: {:cont, zipper, variables}
    end)
    |> elem(1)
    |> remove_duplicates()
  end

  def remove_duplicates(variables),
    do: Enum.uniq_by(variables, fn {name, _, _} -> name end)

  def member?(variables, {name, _, _} = _variable),
    do: Enum.any?(variables, &match?({^name, _, _}, &1))

  def member?(_, _), do: false

  def find_available_variables(%{node: node} = zipper) do
    line = AST.get_start_line(node)

    zipper
    # go to outer scope
    |> Z.find(:prev, fn
      {id, _, _} when id in ~w(defmodule def defp)a -> true
      _ -> false
    end)
    |> Z.node()
    |> find_variables()
    |> Enum.reject(&(AST.get_start_line(&1) >= line))
  end

  def inside_declaration?(%{node: node} = zipper) do
    case parent = Z.up(zipper) do
      %{node: {id, _, [^node, _]}} when id in ~w(def defp <- when =)a ->
        true

      %{node: {:->, _, [^node, _]}} ->
        cond do
          match?(%{node: {:fn, _, _}}, Z.up(parent)) -> true
          match?(%{node: {:case, _, _}}, AST.up(parent, 4)) -> true
          true -> false
        end

      %{node: {_, _, [_ | _]}} ->
        inside_declaration?(parent)

      %{node: [_ | _]} ->
        inside_declaration?(parent)

      %{node: {_, _}} ->
        inside_declaration?(parent)

      _ ->
        false
    end
  end

  # find &{i} usages and replace them with arg{i}
  def turn_captures_into_variables(node) do
    node
    |> Z.zip()
    |> Z.traverse(MapSet.new(), fn
      %{node: {:&, _, [i]}} = zipper, variables when is_number(i) ->
        arg = {String.to_atom("arg#{i}"), [], nil}
        {Z.replace(zipper, arg), MapSet.put(variables, arg)}

      zipper, variables ->
        {zipper, variables}
    end)
  end

  def replace_usages_by_value(node, name, value) do
    node
    |> Z.zip()
    |> Z.traverse_while(fn
      %{node: {:@, _, [{^name, _, nil}]}} = zipper ->
        {:skip, zipper}

      %{node: {:cond, meta, [[{block, clauses}]]}} = zipper ->
        clauses =
          Enum.map(clauses, fn {:->, meta, [condition, _] = clause} ->
            if was_variable_reassigned?(condition, name),
              do: {:->, meta, clause},
              else: {:->, meta, replace_usages_by_value(clause, name, value)}
          end)

        {:skip, Z.replace(zipper, {:cond, meta, [[{block, clauses}]]})}

      %{node: {:->, _, [args, _]}} = zipper ->
        if was_variable_used?(args, name),
          do: {:skip, zipper},
          else: {:cont, zipper}

      %{node: {:=, meta, [args, new_value]}} = zipper ->
        if was_variable_used?(args, name),
          do: {
            :skip,
            zipper
            |> Z.replace({
              :=,
              meta,
              [args, replace_usages_by_value(new_value, name, value)]
            })
            # go up to skip traversing right siblings
            |> Z.up()
          },
          else: {:cont, zipper}

      %{node: {^name, _, nil}} = zipper ->
        {:cont, Z.replace(zipper, value)}

      zipper ->
        {:cont, zipper}
    end)
    |> Z.node()
  end

  defp was_variable_used?(node, name) do
    node
    |> Refactorex.Refactor.Function.actual_args()
    |> member?({name, [], nil})
  end

  defp was_variable_reassigned?(node, name) do
    node
    |> Z.zip()
    |> Z.traverse_while(false, fn
      %{node: {:=, _, [args, _]}} = zipper, false ->
        if was_variable_used?(args, name),
          do: {:halt, zipper, true},
          else: {:cont, zipper, false}

      zipper, false ->
        {:cont, zipper, false}
    end)
    |> elem(1)
  end
end
