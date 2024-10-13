defmodule Refactorex.Parser do
  alias Refactorex.Refactor.Selection

  def parse_inputs(original, range) do
    range = update_in(range.start.line, &(&1 + 1))
    range = update_in(range.end.line, &(&1 + 1))

    with {:ok, selection_or_line} <- Selection.selection_or_line(original, range),
         {:ok, macro} <- Sourceror.parse_string(original) do
      zipper = Sourceror.Zipper.zip(macro)

      {:ok, zipper, selection_or_line}
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
        character: character - 1 - count_while_identifier(Enum.reverse(left))
      },
      end: %{
        line: line,
        character: character - 1 + count_while_identifier(right)
      }
    }
  end

  defp count_while_identifier(characters) do
    Enum.reduce_while(characters, 0, fn i, count ->
      if String.match?(i, ~r/^[a-zA-Z0-9_?!]+$/),
        do: {:cont, count + 1},
        else: {:halt, count}
    end)
  end
end
