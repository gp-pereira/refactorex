defmodule Refactorex.Refactor.Function do
  alias Sourceror.Zipper, as: Z
  alias Refactorex.Refactor.Module

  import Sourceror.Identifier

  def definition?(node)
  def definition?({:def, _, _}), do: true
  def definition?({:defp, _, _}), do: true
  def definition?(_node), do: false

  def anonymous?(node)
  def anonymous?({:&, _, [i]}) when is_number(i), do: false
  def anonymous?({:&, _, _}), do: true
  def anonymous?({:fn, _, _}), do: true
  def anonymous?(_), do: false

  def call?({_, meta, _} = node), do: !!meta[:closing] and is_call(node)
  def call?(_), do: false

  def find_definitions(%{node: {name, _, args}} = zipper) do
    num_args =
      case Z.up(zipper) do
        %{node: {:/, _, [_, {:__block__, _, [num_args]}]}} ->
          num_args

        %{node: {:|>, _, _}} ->
          length(args) + 1

        _ ->
          length(args)
      end

    zipper
    |> Module.find_in_scope(fn
      {_, _, [{:when, _, [{^name, _, function_args}, _]}, _]} = node ->
        definition?(node) and length(function_args) == num_args

      {_, _, [{^name, _, function_args}, _]} = node ->
        definition?(node) and length(function_args) == num_args

      _ ->
        false
    end)
  end

  def new_private_function(zipper, name, args, body) do
    private_function =
      {:defp, [do: [], end: []],
       [
         case unpin_args(args) do
           [{:when, _, [args, guard]} | other_args] ->
             {:when, [], [{name, [], [args | other_args]}, guard]}

           {:when, _, [{_, _, args}, guard]} ->
             {:when, [], [{name, [], args}, guard]}

           args ->
             {name, [], args}
         end,
         [{{:__block__, [], [:do]}, body}]
       ]}

    Module.update_scope(zipper, &(&1 ++ [private_function]))
  end

  def next_available_function_name(zipper, base_name) do
    Module.next_available_name(
      zipper,
      base_name,
      &definition?/1,
      fn {_, _, [{name, _, _}, _]} -> name end
    )
  end

  def go_to_block(zipper) do
    zipper
    |> Z.down()
    |> Z.right()
    |> Z.down()
  end

  defp unpin_args(args) do
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
end
