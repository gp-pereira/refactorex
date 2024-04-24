defmodule Refactorex.RefactorCase do
  use ExUnit.CaseTemplate

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

      original = String.trim(unquote(original))
      expected = String.trim(unquote(expected))

      range = range_from_markers(original)
      zipper = text_to_zipper(original)

      if opts[:range], do: Logger.info("Range: #{inspect(range)}")

      assert true == module.available?(zipper, range)

      refactored = module.refactor(zipper, range)

      if opts[:raw] do
        assert Sourceror.parse_string!(expected) == Sourceror.parse_string!(refactored)
      else
        assert String.split(expected, "\n") == String.split(refactored, "\n")
      end
    end
  end

  defmacro assert_not_refactored(module, original, _opts \\ []) do
    quote do
      module = unquote(module)
      original = unquote(original)

      range = range_from_markers(original)

      assert false == module.available?(text_to_zipper(original), range)
    end
  end

  def range_from_markers(text) do
    text
    |> String.split("\n")
    |> Enum.with_index()
    |> Enum.filter(fn {text, _} -> String.match?(text, @marker_regex) end)
    |> then(fn
      [{text, line}] ->
        %{
          start: %{
            line: line + 1,
            character: String.length(text)
          },
          end: %{
            line: line + 1,
            character: String.length(text)
          }
        }

      [{start_text, start_line}, {end_text, end_line}] ->
        %{
          start: %{
            line: start_line + 1,
            character: String.length(start_text)
          },
          end: %{
            line: end_line - 1,
            character: String.length(end_text)
          }
        }
    end)
  end

  def print_tree(text) do
    IO.puts("")

    text
    |> text_to_zipper()
    |> Refactorex.TreePrinter.print()

    text
  end

  def text_to_zipper(original) do
    original
    |> String.split("\n")
    |> Enum.reject(&String.match?(&1, @marker_regex))
    |> Enum.join("\n")
    |> Sourceror.parse_string!()
    |> Sourceror.Zipper.zip()
  end
end
