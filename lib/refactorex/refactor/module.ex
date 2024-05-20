defmodule Refactorex.Refactor.Module do
  alias Sourceror.Zipper, as: Z
  alias Refactorex.Refactor.Function

  def inside_one?(zipper),
    do: !!go_to_outer_module(zipper)

  def add_private_function(zipper, name, args, body) do
    add_function(
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

  def add_function(zipper, function),
    do: update_scope(zipper, &(&1 ++ [function]))

  def update_scope(zipper, updater) do
    zipper
    |> go_to_scope()
    |> Z.update(fn {_, _, scope} ->
      {:__block__, [], updater.(scope)}
    end)
  end

  def next_available_function_name(zipper, name) do
    next_available_name(
      zipper,
      &Function.definition?/1,
      fn {_, _, [{function_name, _, _}, _]} -> function_name end,
      name
    )
  end

  defp next_available_name(zipper, filter, node_namer, base_name) do
    zipper
    |> find_in_scope(filter)
    |> Enum.reduce(base_name, fn
      node, current_name ->
        case Regex.run(~r/#{base_name}(\d*)/, Atom.to_string(node_namer.(node))) do
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

  def find_in_scope(zipper, filter) do
    zipper
    |> go_to_scope()
    |> Z.node()
    |> Z.children()
    |> Enum.filter(filter)
  end

  defp go_to_scope(zipper) do
    zipper
    |> go_to_outer_module()
    |> Z.down()
    |> Z.right()
    |> Z.down()
    |> Z.down()
    |> Z.right()
    |> Z.update(fn
      {:__block__, _, scope} ->
        {:__block__, [], scope}

      scope ->
        {:__block__, [], [scope]}
    end)
  end

  defp go_to_outer_module(zipper) do
    Z.find(zipper, :prev, fn
      {:defmodule, _, _} ->
        true

      _ ->
        false
    end)
  end
end
