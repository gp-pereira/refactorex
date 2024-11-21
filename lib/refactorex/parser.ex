defmodule Refactorex.Parser do
  alias Sourceror.Zipper, as: Z

  @newline_placeholder "-----placeholder-----"

  def parse_metadata(%{} = map) do
    map
    |> Enum.map(fn {k, v} -> {String.to_atom(k), parse_metadata(v)} end)
    |> Map.new()
  end

  def parse_metadata(not_map), do: not_map

  def parse_inputs(text, range) do
    range = update_in(range.start.line, &(&1 + 1))
    range = update_in(range.end.line, &(&1 + 1))

    with {:ok, macro} <- Sourceror.parse_string(text),
         {:ok, selection_or_line} <- selection_or_line(text, range) do
      {:ok, Z.zip(macro), selection_or_line}
    else
      {:error, _} -> {:error, :parse_error}
    end
  end

  def position_to_range(text, %{line: line, character: character}) do
    text = replace_newline_with_placeholder(text)

    {left, right} =
      text
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

  def selection_or_line(_text, range)
      when range.start == range.end,
      do: {:ok, range.start.line}

  def selection_or_line(text, range) do
    text
    |> erase_outside_range(range)
    |> Sourceror.parse_string()
  end

  def erase_outside_range(text, range) do
    text
    |> String.replace("\r", "")
    |> replace_newline_with_placeholder()
    |> String.split("\n")
    |> Stream.with_index(1)
    |> Stream.map(fn
      {line, i} when i > range.start.line and i < range.end.line ->
        line

      {line, i} when i == range.start.line and i == range.end.line ->
        line
        |> remove_line_start(range)
        |> remove_line_end(range)

      {line, i} when i == range.start.line ->
        remove_line_start(line, range)

      {line, i} when i == range.end.line ->
        remove_line_end(line, range)

      _ ->
        ""
    end)
    |> Enum.join("\n")
    |> replace_placeholder_with_newline()
  end

  defp replace_newline_with_placeholder(text) do
    {:ok, macro} = Sourceror.parse_string(text)

    macro
    |> Z.zip()
    |> Z.traverse(fn
      %{node: {id, meta, [string]}} = zipper when is_bitstring(string) ->
        string = String.replace(string, "\n", "#{@newline_placeholder}\n")
        Z.replace(zipper, {id, meta, [string]})

      zipper ->
        zipper
    end)
    |> Z.node()
    |> Sourceror.to_string()
  end

  defp replace_placeholder_with_newline(text),
    do: String.replace(text, @newline_placeholder, "\n")

  defp remove_line_start(line, %{start: %{character: character}}) do
    {_, line} = String.split_at(line, character)
    String.pad_leading(line, character + String.length(line), " ")
  end

  defp remove_line_end(line, %{end: %{character: character}}) do
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
