defmodule Refactorex.RefactorCase do
  use ExUnit.CaseTemplate

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

      range = range(original)

      zipper =
        original
        |> String.replace(~r/\t*#(?:\s*[v^])\n/, "")
        |> Sourceror.parse_string!()
        |> Sourceror.Zipper.zip()

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
      original = String.trim(unquote(original))

      zipper =
        original
        |> String.replace(~r/\t*#(?:\s*[v^])\n/, "")
        |> Sourceror.parse_string!()
        |> Sourceror.Zipper.zip()

      assert false == module.available?(zipper, range(original))
    end
  end

  def range(text) do
    text
    |> String.split("\n")
    |> Enum.with_index()
    |> Enum.filter(fn {text, _} -> Regex.match?(~r/\s*#(?:\s*[v^])/, text) end)
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
            line: end_line,
            character: String.length(end_text)
          }
        }
    end)
  end
end
