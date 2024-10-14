defmodule Refactorex.Refactor.Constant do
  alias Sourceror.Zipper, as: Z

  def find_definition(zipper, constant_id) do
    zipper
    |> Z.top()
    |> Z.traverse_while(nil, fn
      %{node: {:@, _, [{_, _, nil}]}} = zipper, _ ->
        {:cont, zipper, nil}

      %{node: {:@, _, [{^constant_id, _, _} = node]}} = zipper, _ ->
        {:halt, zipper, node}

      zipper, _ ->
        {:cont, zipper, nil}
    end)
    |> elem(1)
  end

  def find_definition_and_usages(zipper, constant_id) do
    zipper
    |> Z.top()
    |> Z.traverse_while({nil, []}, fn
      %{node: {:@, _, [{^constant_id, _, nil} = node]}} = zipper, {def, usages} ->
        {:cont, zipper, {def, [node | usages]}}

      %{node: {:@, _, [{^constant_id, _, _} = node]}} = zipper, {_, usages} ->
        {:cont, zipper, {node, usages}}

      zipper, acc ->
        {:cont, zipper, acc}
    end)
    |> elem(1)
  end
end
