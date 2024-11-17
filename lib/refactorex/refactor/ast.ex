defmodule Refactorex.Refactor.AST do
  alias Sourceror.Zipper, as: Z

  @confusing_meta_tags ~w(
    end_of_expression
    leading_comments
    trailing_comments
    closing
  )a

  def starts_at?(macro, line), do: get_start_line(macro) == line

  def get_start_line(macro) do
    macro
    |> Z.zip()
    |> Z.traverse(:infinity, fn
      %{node: {_, meta, _}} = zipper, min_line ->
        if is_nil(meta[:line]),
          do: {zipper, min_line},
          else: {zipper, min(min_line, meta[:line])}

      zipper, min_line ->
        {zipper, min_line}
    end)
    |> elem(1)
  end

  def equal?(macro, macro), do: true

  def equal?({id, _, _} = macro1, {id, _, _} = macro2),
    do: simpler_meta(macro1) == simpler_meta(macro2)

  def equal?(_, _), do: false

  defp simpler_meta(node) do
    node
    |> Z.zip()
    |> Z.traverse(fn
      %{node: {id, meta, block}} = zipper ->
        Z.replace(zipper, {id, Keyword.drop(meta, @confusing_meta_tags), block})

      zipper ->
        zipper
    end)
    |> Z.node()
  end

  def find(%Z{} = zipper, finder) do
    zipper
    |> Z.top()
    |> Z.traverse([], fn %{node: node} = zipper, nodes ->
      if finder.(node),
        do: {zipper, [node | nodes]},
        else: {zipper, nodes}
    end)
    |> elem(1)
  end

  def find(not_zipper, finder), do: find(Z.zip(not_zipper), finder)

  def go_to_node(zipper, node) do
    zipper
    |> Z.top()
    |> Z.traverse_while(nil, fn
      %{node: ^node} = zipper, nil ->
        {:halt, zipper, zipper}

      zipper, nil ->
        {:cont, zipper, nil}
    end)
    |> elem(1)
  end

  def up(zipper, times \\ 1)
  def up(nil, _), do: nil
  def up(zipper, 0), do: zipper
  def up(zipper, times), do: zipper |> Z.up() |> up(times - 1)

  def up_until(zipper, matcher_fn)
  def up_until(nil, _), do: nil

  def up_until(%{node: node} = zipper, matcher_fn) do
    if matcher_fn.(node),
      do: zipper,
      else: up_until(Z.up(zipper), matcher_fn)
  end

  def inside?(zipper, matcher_fn), do: !!up_until(zipper, matcher_fn)
end
