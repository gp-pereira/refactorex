defmodule Refactorex.Refactor.Module do
  alias Sourceror.Zipper, as: Z

  def inside_one?(zipper), do: !!go_to_definition(zipper)

  def find_in_scope(zipper, filter_fn) do
    zipper
    |> go_to_scope()
    |> Z.node()
    |> Z.children()
    |> Enum.filter(filter_fn)
  end

  def update_scope(zipper, updater_fn) do
    zipper
    |> go_to_scope()
    |> Z.update(fn {_, _, scope} ->
      {:__block__, [], updater_fn.(scope)}
    end)
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

  defp go_to_scope(zipper) do
    zipper
    |> go_to_definition()
    |> Z.down()
    |> Z.right()
    |> Z.down()
    |> Z.down()
    |> Z.right()
    |> Z.update(fn
      {:__block__, meta, scope} ->
        {:__block__, meta, scope}

      scope ->
        {:__block__, [], [scope]}
    end)
  end

  defp go_to_definition(nil), do: nil
  defp go_to_definition(%{node: {:defmodule, _, _}} = zipper), do: zipper
  defp go_to_definition(zipper), do: zipper |> Z.up() |> go_to_definition()
end
