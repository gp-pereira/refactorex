defmodule Refactorex.Refactor.Module do
  alias Sourceror.Zipper, as: Z
  alias Refactorex.Refactor.AST

  def inside_one?(zipper), do: !!go_to_definition(zipper)

  def place_node(zipper, node, placer_fn) do
    zipper
    |> go_to_scope()
    |> Z.update(fn
      {:__block__, meta, []} ->
        {:__block__, meta, [node]}

      {:__block__, meta, scope} ->
        {:__block__, meta, List.insert_at(scope, placer_fn.(scope) || 0, node)}
    end)
  end

  def find_in_scope(zipper, filter_fn) do
    zipper
    |> go_to_scope()
    |> Z.node()
    |> Z.children()
    |> Enum.filter(filter_fn)
  end

  def next_available_name(zipper, base_name, filter_fn, node_namer_fn) do
    zipper
    |> find_in_scope(filter_fn)
    |> Enum.reduce(base_name, fn
      node, current_name ->
        node_name = node |> node_namer_fn.() |> Atom.to_string()

        case Regex.run(~r/#{base_name}(\d*)/, node_name) do
          [_, ""] ->
            "#{base_name}1"

          [_, i] ->
            "#{base_name}#{String.to_integer(i) + 1}"

          _ ->
            current_name
        end
    end)
    |> String.to_atom()
  end

  def go_to_scope(zipper) do
    zipper
    |> go_to_definition()
    |> Z.down()
    |> Z.right()
    |> Z.down()
    # normalize module scope
    |> Z.update(fn
      # multiple statements
      {{:__block__, _, [:do]} = do_block, {:__block__, _, _} = block} ->
        {do_block, block}

      # single statement
      {{:__block__, _, [:do]} = do_block, scope} ->
        {do_block, {:__block__, [], [scope]}}

      # no statement
      {:{}, [], [{:__block__, _, [:do]} = do_block]} ->
        {do_block, {:__block__, [], []}}
    end)
    |> Z.down()
    |> Z.right()
  end

  defp go_to_definition(zipper),
    do: AST.up_until(zipper, &match?({:defmodule, _, _}, &1))
end
