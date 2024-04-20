defmodule Refactorex.Refactor.SelectionRange do
  import Sourceror

  def starts_on_node_line?(selection, node),
    do: selection.start.line == get_line(node)
end
