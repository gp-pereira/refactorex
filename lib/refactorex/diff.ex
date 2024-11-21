defmodule Refactorex.Diff do
  def from_original(%{refactored: refactored} = refactoring, original),
    do: %{refactoring | diffs: find_diffs(original, refactored)}

  def find_diffs(original, refactored) do
    original = original |> String.trim() |> String.split(os_newline())
    refactored = refactored |> String.trim() |> String.split("\n")

    original
    |> List.myers_difference(refactored)
    |> accumulate_diffs([], 1)
  end

  defp accumulate_diffs([], diffs, _), do: diffs

  defp accumulate_diffs([{:eq, lines} | rest], diffs, line),
    do: accumulate_diffs(rest, diffs, length(lines) + line)

  defp accumulate_diffs([{:del, del} | [{:ins, ins} | rest]], diffs, line) do
    accumulate_diffs(
      rest,
      [
        %{
          text: Enum.join(ins, "\n"),
          range: %{
            start: %{
              line: line - 1,
              character: 0
            },
            end: %{
              line: line + length(del) - 2,
              character: del |> List.last() |> String.length()
            }
          }
        }
        | diffs
      ],
      line + length(del)
    )
  end

  defp accumulate_diffs([{:ins, ins} | rest], diffs, line) do
    accumulate_diffs(
      rest,
      [
        %{
          text: (ins ++ [""]) |> Enum.join("\n"),
          range: %{
            start: %{
              line: line - 1,
              character: 0
            },
            end: %{
              line: line - 1,
              character: 0
            }
          }
        }
        | diffs
      ],
      line
    )
  end

  defp accumulate_diffs([{:del, del} | rest], diffs, line) do
    accumulate_diffs(
      rest,
      [
        %{
          text: "",
          range: %{
            start: %{
              line: line - 1,
              character: 0
            },
            end: %{
              line: line + length(del) - 1,
              character: 0
            }
          }
        }
        | diffs
      ],
      line + length(del)
    )
  end

  defp os_newline() do
    case :os.type() do
      {:win32, _} -> "\r\n"
      {:unix, _} -> "\n"
    end
  end
end
