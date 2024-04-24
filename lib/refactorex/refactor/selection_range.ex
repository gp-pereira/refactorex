defmodule Refactorex.Refactor.SelectionRange do
  import Sourceror

  def starts_on_node_line?(selection, node),
    do: selection.start.line == get_line(node)

  def selects_this_node?(range, node, opts \\ []) do
    node_start = get_start_position(node)
    node_end = get_end_position(node)

    allowed_delta = Keyword.get(opts, :column_delta, 0)

    cond do
      range.start.line != node_start[:line] ->
        false

      range.end.line != node_end[:line] ->
        false

      abs(range.start.character - node_start[:column]) > allowed_delta ->
        false

      abs(range.end.character - node_end[:column]) > allowed_delta ->
        false

      true ->
        true
    end
  end
end
