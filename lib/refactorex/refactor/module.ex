defmodule Refactorex.Refactor.Module do
  alias Sourceror.Zipper, as: Z

  def inside_one?(zipper),
    do: !!go_to_outer_module(zipper)

  def add_function(zipper, function),
    do: update_scope(zipper, &(&1 ++ [function]))

  def update_scope(zipper, updater) do
    zipper
    |> go_to_scope()
    |> Z.update(fn {_, _, scope} ->
      {:__block__, [], updater.(scope)}
    end)
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
