defmodule Refactorex.Refactor.SelectionRange do
  alias Sourceror.Zipper, as: Z

  import Sourceror

  def starts_on_node_line?(range, node),
    do: range.start.line == get_line(node)

  def selects_this_node?(range, zipper, opts \\ []) do
    node_start = get_start_position(zipper.node)

    cond do
      range.start.line != node_start[:line] ->
        false

      abs(range.start.character - node_start[:column]) > allowed_delta(opts) ->
        false

      # some kind of nodes have misguiding info about where they end,
      # so we are using the parent node as a proxy for the child end
      ends_before_node?(range, Z.up(zipper), opts) ->
        true

      not ends_before_node?(range, zipper, opts) ->
        false

      true ->
        true
    end
  end

  defp ends_before_node?(_range, nil, _opts), do: false

  defp ends_before_node?(range, zipper, opts) do
    node_end = get_end_position(zipper.node)

    cond do
      range.end.line < node_end[:line] ->
        true

      range.end.line > node_end[:line] ->
        false

      abs(range.end.character - node_end[:column]) > allowed_delta(opts) ->
        false

      true ->
        true
    end
  end

  defp allowed_delta(opts), do: Keyword.get(opts, :column_delta, 0)
end
