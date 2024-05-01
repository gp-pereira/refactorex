defmodule Refactorex.Refactor.Selection do
  alias Sourceror.Zipper, as: Z

  @newline_replacement "$$replacement$$"

  def node_or_line(text, range) do
    if empty_range?(range) do
      {:ok, range.start.line}
    else
      with {:ok, text} <- erase_outside_range(text, range),
           {:ok, node} <- Sourceror.parse_string(text) do
        {:ok, node}
      end
    end
  end

  def empty_range?(range) do
    range.start.line == range.end.line and
      range.start.character == range.end.character
  end

  def erase_outside_range(text, range) do
    without_newlines(
      text,
      &(&1
        |> String.split("\n")
        |> Stream.with_index()
        |> Stream.map(fn {line, i} -> {line, i + 1} end)
        |> Stream.map(fn
          {line, i} when i > range.start.line and i < range.end.line ->
            line

          {line, i} when i == range.start.line and i == range.end.line ->
            line
            |> remove_start(range)
            |> remove_end(range)

          {line, i} when i == range.start.line ->
            remove_start(line, range)

          {line, i} when i == range.end.line ->
            remove_end(line, range)

          _ ->
            ""
        end)
        |> Enum.join("\n"))
    )
  end

  defp without_newlines(text, func) do
    with {:ok, macro} <- Sourceror.parse_string(text) do
      macro
      |> Z.zip()
      |> Z.traverse(fn
        %{node: {id, meta, [string]}} = zipper when is_bitstring(string) ->
          string = String.replace(string, "\n", @newline_replacement)
          Z.update(zipper, fn _ -> {id, meta, [string]} end)

        zipper ->
          zipper
      end)
      |> Z.node()
      |> Sourceror.to_string()
      |> func.()
      |> String.replace(@newline_replacement, "\n")
      |> then(&{:ok, &1})
    end
  end

  defp remove_start(line, %{start: %{character: character}}) do
    {_, line} = String.split_at(line, character)
    String.pad_leading(line, character + String.length(line), " ")
  end

  defp remove_end(line, %{end: %{character: character}}) do
    {line, _} = String.split_at(line, character)
    line
  end
end
