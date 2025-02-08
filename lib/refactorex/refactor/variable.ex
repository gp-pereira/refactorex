defmodule Refactorex.Refactor.Variable do
  alias Refactorex.Dataflow
  alias Refactorex.Refactor.AST
  alias Sourceror.Zipper, as: Z

  def at_one?(%{node: {name, _, nil}} = zipper) do
    cond do
      not is_atom(name) or name in ~w(binary _)a ->
        false

      match?(%{node: {:@, _, _}}, Z.up(zipper)) ->
        false

      true ->
        true
    end
  end

  def at_one?(_zipper), do: false

  def was_declared?(zipper, variable),
    do: not Enum.empty?(find_all_references(zipper, variable))

  def find_all_references(zipper, {name, _, _} = variable) do
    zipper
    |> Z.topmost_root()
    |> Dataflow.analyze()
    |> Stream.map(fn {d, u} -> [d | u] end)
    |> Enum.find([], fn
      [{^name, _, _} | _] = references ->
        Enum.any?(references, &AST.equal?(&1, variable))

      _ ->
        false
    end)
  end

  # remove later ?
  def find_available_variables(%{node: node} = zipper) do
    line = AST.get_start_line(node)

    zipper
    # go to outer scope
    |> Z.find(:prev, fn
      {id, _, _} when id in ~w(defmodule def defp)a -> true
      _ -> false
    end)
    |> Z.node()
    |> list_unique_variables()
    |> Enum.reject(&(AST.get_start_line(&1) >= line))
  end

  def list_unique_variables(node, filter_fn \\ fn _zipper -> true end) do
    node
    |> list_variables(filter_fn)
    |> remove_duplicates()
  end

  def list_unpinned_variables(node),
    do: list_variables(node, &(not match?(%{node: {:^, _, _}}, Z.up(&1))))

  def list_variables(node, filter_fn \\ fn _zipper -> true end) do
    node
    |> Z.zip()
    |> Z.traverse_while([], fn
      %{node: node} = zipper, variables ->
        cond do
          not at_one?(zipper) ->
            {:cont, zipper, variables}

          not filter_fn.(zipper) ->
            {:cont, zipper, variables}

          true ->
            {:cont, zipper, variables ++ [node]}
        end
    end)
    |> elem(1)
  end

  def remove_duplicates(variables),
    do: Enum.uniq_by(variables, fn {name, _, _} -> name end)

  def member?(variables, {name, _, _} = _variable),
    do: Enum.any?(variables, &match?({^name, _, _}, &1))

  def member?(_, _), do: false

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
    |> then(fn {zipper, args} -> {zipper, Enum.into(args, [])} end)
  end
end
