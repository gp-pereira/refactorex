defmodule Refactorex.Refactor.Module do
  alias Sourceror.Zipper, as: Z

  def inside_one?(zipper),
    do: !!go_to_outer_module(zipper)

  def add_function(zipper, function) do
    zipper
    |> go_to_outer_module()
    # go to module functions
    |> Z.down()
    |> Z.right()
    |> Z.down()
    |> Z.down()
    |> Z.right()
    |> Z.update(fn
      {:__block__, _, other_functions} ->
        {:__block__, [], other_functions ++ [function]}

      single_function ->
        {:__block__, [], [single_function, function]}
    end)
  end

  def go_to_outer_module(zipper) do
    Z.find(zipper, :prev, fn
      {:defmodule, _, _} ->
        true

      _ ->
        false
    end)
  end
end
