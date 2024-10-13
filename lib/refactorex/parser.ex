defmodule Refactorex.Parser do
  alias Sourceror.Zipper, as: Z

  @newline_replacement "$$replacement$$"

  def parse_inputs(original, range) do
    range = update_in(range.start.line, &(&1 + 1))
    range = update_in(range.end.line, &(&1 + 1))

    with {:ok, macro} <- Sourceror.parse_string(original),
         {:ok, selection_or_line} <- selection_or_line(original, range) do
      {:ok, Z.zip(macro), selection_or_line}
    else
      {:error, _} -> {:error, :parse_error}
    end
  end

  def parse_metadata(%{} = map) do
    map
    |> Enum.map(fn {k, v} -> {String.to_atom(k), parse_metadata(v)} end)
    |> Map.new()
  end

  def parse_metadata(not_map), do: not_map

  def position_to_range(original, %{line: line, character: character}) do
    {left, right} =
      original
      |> String.split("\n")
      |> Enum.at(line)
      |> String.split("")
      |> Enum.split(character)

    %{
      start: %{
        line: line,
        character: character - 1 - count_while_name(Enum.reverse(left))
      },
      end: %{
        line: line,
        character: character - 1 + count_while_name(right)
      }
    }
  end

  def selection_or_line(_original, range)
      when range.start == range.end,
      do: {:ok, range.start.line}

  def selection_or_line(original, range) do
    with {:ok, selected_text} <- erase_outside_range(original, range),
         {:ok, selection} <- Sourceror.parse_string(selected_text) do
      {:ok, selection}
    end
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
          string = String.replace(string, "\n", "#{@newline_replacement}\n")
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

  defp count_while_name(characters) do
    Enum.reduce_while(characters, 0, fn i, count ->
      if String.match?(i, ~r/^[a-zA-Z0-9_?!]+$/),
        do: {:cont, count + 1},
        else: {:halt, count}
    end)
  end
end
