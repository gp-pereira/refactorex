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
end
