defmodule Refactorex.Refactor.Function do
  alias Refactorex.Refactor.Variable
  alias Sourceror.Zipper, as: Z

  def definition?(node)
  def definition?({:def, _, _}), do: true
  def definition?({:defp, _, _}), do: true
  def definition?(_node), do: false

  def anonymous?(node)
  def anonymous?({:&, _, [i]}) when is_number(i), do: false
  def anonymous?({:&, _, _}), do: true
  def anonymous?({:fn, _, _}), do: true
  def anonymous?(_), do: false

  def actual_args(args) do
    args
    |> Z.zip()
    |> Z.traverse_while([], fn
      %{node: node} = zipper, actual_args ->
        cond do
          not Variable.at_one?(zipper) ->
            {:cont, zipper, actual_args}

          # pinned args are not actual args
          match?(%{node: {:^, _, _}}, Z.up(zipper)) ->
            {:cont, zipper, actual_args}

          true ->
            {:cont, zipper, actual_args ++ [node]}
        end
    end)
    |> elem(1)
  end

  def unpin_args(args) do
    args
    |> Z.zip()
    |> Z.traverse(fn
      %{node: {:^, _, [arg]}} = zipper ->
        Z.update(zipper, fn _ -> arg end)

      zipper ->
        zipper
    end)
    |> Z.node()
  end

  def has_multiple_statements?(zipper) do
    zipper
    |> go_to_block()
    |> then(fn
      %{node: {{:__block__, _, _}, {:__block__, _, [_]}}} ->
        false

      %{node: {{:__block__, _, _}, {:__block__, _, [_ | _]}}} ->
        true

      _ ->
        false
    end)
  end

  def go_to_block(zipper) do
    zipper
    |> Z.down()
    |> Z.right()
    |> Z.down()
  end
end
