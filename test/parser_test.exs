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

      assert "\n\n\n                fn filename ->\n      file = File.read!(\"\#{filename}.\#{ext}\")\n      String.split(file, \"\\n\")\n    end\n\n" ==
               Parser.erase_outside_range(original, range)
    end
  end
end
