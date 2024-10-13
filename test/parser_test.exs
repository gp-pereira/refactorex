defmodule Refactorex.ParserTest do
  use Refactorex.RefactorCase

  alias Refactorex.Parser

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
