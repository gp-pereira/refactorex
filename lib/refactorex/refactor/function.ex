defmodule Refactorex.Refactor.Function do
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
    Refactorex.Refactor.Variable.find_variables(
      args,
      # pinned args are not actual args
      reject: &match?(%{node: {:^, _, _}}, Z.up(&1)),
      # functions can have repeated args
      unique: false
    )
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
