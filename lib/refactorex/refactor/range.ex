defmodule Refactorex.Refactor.Range do
  def same_start_line?(%{start: %{line: line}}, meta), do: line == meta[:line]

  def range_inside_of?(range, start_meta, end_meta) do
    [
      [
        # below start line
        range.start.line > start_meta[:line],
        # same start line and after start character
        range.start.line == start_meta[:line] and
          range.start.character >= start_meta[:column]
      ]
      |> Enum.any?(),
      [
        # above end line
        range.end.line < end_meta[:line],
        # same end line and before end character
        range.end.line == end_meta[:line] and
          range.end.character <= end_meta[:column]
      ]
      |> Enum.any?()
    ]
    |> Enum.all?()
  end
end
