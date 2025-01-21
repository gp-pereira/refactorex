defmodule Refactorex.ParserTest do
  use Refactorex.RefactorCase

  alias Refactorex.Parser

  describe "position_to_range/2" do
    test "parse the selected node when passed a position" do
      original = """
      defmodule Foo do
        def do_bar?(arg) do
        end
      end
      """

      position = %{line: 1, character: 10}

      assert %{
               start: %{line: 1, character: 6},
               end: %{line: 1, character: 13}
             } = range = Parser.position_to_range(original, position)

      assert {
               :ok,
               %Sourceror.Zipper{},
               {:do_bar?, _, nil}
             } = Parser.parse_inputs(original, range)
    end
  end

  describe "erase_outside_range/2" do
    test "erases everything outside the selected range" do
      original = """
      defmodule Foo do
        def read_files(filenames, ext) do
          filenames
          #           v
          |> Enum.map(fn filename ->
            file = File.read!("\#{filename}.\#{ext}")
            String.split(file, "\\n")
          end)
          # ^
        end
      end
      """

      range = range_from_markers(original)
      original = remove_markers(original)

      assert [
               "",
               "",
               "",
               "                fn filename ->",
               "      file = File.read!(\"\#{filename}.\#{ext}\")",
               "      String.split(file, \"\\n\")",
               "    end",
               "",
               "",
               ""
             ]
             |> Enum.join("\n") == Parser.erase_outside_range(original, range)
    end

    test "keeps the original formatting even if it's not up to the standards" do
      original = """
      defmodule Foo do
        def read_files(filenames, ext) do
        # v
          case filenames do
            variable_name -> really_really_really_really_really_really_really_really_long_function(variable_name)
          end
        #   ^
        end
      end
      """

      range = range_from_markers(original)
      original = remove_markers(original)

      assert [
               "",
               "",
               "    case filenames do",
               "      variable_name -> really_really_really_really_really_really_really_really_long_function(variable_name)",
               "    end",
               "",
               "",
               ""
             ]
             |> Enum.join("\n") == Parser.erase_outside_range(original, range)
    end
  end
end
