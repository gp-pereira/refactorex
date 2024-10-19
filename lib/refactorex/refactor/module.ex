defmodule Refactorex.Refactor.Module do
  alias Sourceror.Zipper, as: Z
  alias Refactorex.Refactor.Function

  def inside_one?(zipper), do: !!go_to_definition(zipper)

  def add_private_function(zipper, name, args, body) do
    private_function =
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

    update_scope(zipper, &(&1 ++ [private_function]))
  end

  def find_in_scope(zipper, filter) do
    zipper
    |> go_to_scope()
    |> Z.node()
    |> Z.children()
    |> Enum.filter(filter)
  end

  def update_scope(zipper, updater) do
    zipper
    |> go_to_scope()
    |> Z.update(fn {_, _, scope} ->
      {:__block__, [], updater.(scope)}
    end)
  end

  def next_available_function_name(zipper, base_name) do
    next_available_name(
      zipper,
      base_name,
      &Function.definition?/1,
      fn {_, _, [{name, _, _}, _]} -> name end
    )
  end

  def next_available_constant_name(zipper, base_name) do
    next_available_name(
      zipper,
      base_name,
      &match?({:@, _, _}, &1),
      fn {_, _, [{name, _, _}]} -> name end
    )
  end

  def next_available_name(zipper, base_name, filter, node_namer) do
    zipper
    |> find_in_scope(filter)
    |> Enum.reduce(base_name, fn
      node, current_name ->
        node_name = node |> node_namer.() |> Atom.to_string()

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

  defp go_to_definition(zipper) do
    Z.find(zipper, :prev, fn
      {:defmodule, _, _} ->
        true

      _ ->
        false
    end)
  end

  defp go_to_scope(zipper) do
    zipper
    |> go_to_definition()
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
end
