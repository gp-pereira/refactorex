defmodule Refactorex.RefactorCase do
  use ExUnit.CaseTemplate

  alias Refactorex.Parser

  @marker_regex ~r/\s*#\s*[v\^]/

  using(opts) do
    quote do
      use ExUnit.Case, unquote(opts)

      import Refactorex.RefactorCase

      require Logger
    end
  end

  defmacro assert_refactored(module, original, expected, opts \\ []) do
    quote do
      module = unquote(module)
      opts = unquote(opts)

      original = unquote(original) |> String.trim()
      expected = unquote(expected) |> String.trim() |> String.replace("\r", "")

      range = range_from_markers(original)
      original = remove_markers(original)
      zipper = text_to_zipper(original)

      {:ok, selection_or_line} = Parser.selection_or_line(original, range)

      assert true == module.available?(zipper, selection_or_line)

      refactored = module.execute(zipper, selection_or_line)

      if opts[:raw] do
        assert Sourceror.parse_string!(expected) == Sourceror.parse_string!(refactored)
      else
        expected = assert String.split(expected, "\n") == String.split(refactored, "\n")
      end
    end
  end

  defmacro assert_not_refactored(module, original, _opts \\ []) do
    quote do
      module = unquote(module)
      original = unquote(original)

      range = range_from_markers(original)
      original = remove_markers(original)
      zipper = text_to_zipper(original)

      {:ok, selection_or_line} = Parser.selection_or_line(original, range)

      assert false == module.available?(zipper, selection_or_line)
    end
  end

  def range_from_markers(text) do
    text
    |> String.replace("\r", "")
    |> String.split("\n")
    |> Enum.with_index()
    |> Enum.filter(fn {text, _} -> String.match?(text, @marker_regex) end)
    |> then(fn
      [{text, line}] ->
        %{
          start: %{
            line: line + 1,
            character: String.length(text) - 1
          },
          end: %{
            line: line + 1,
            character: String.length(text) - 1
          }
        }

      [{start_text, start_line}, {end_text, end_line}] ->
        %{
          start: %{
            line: start_line + 1,
            character: String.length(start_text) - 1
          },
          end: %{
            line: end_line - 1,
            character: String.length(end_text)
          }
        }
    end)
  end

  def windows?(), do: match?({:win32, _}, :os.type())

  def print_tree(text) do
    IO.puts("")

    text
    |> text_to_zipper()
    |> Refactorex.TreePrinter.print()

    text
  end

  def text_to_zipper(text) do
    text
    |> Sourceror.parse_string!()
    |> Sourceror.Zipper.zip()
  end

  def remove_markers(text) do
    text
    |> String.split("\n")
    |> Enum.reject(&String.match?(&1, @marker_regex))
    |> Enum.join("\n")
  end

  def placeholder, do: Refactorex.Refactor.placeholder()
end
