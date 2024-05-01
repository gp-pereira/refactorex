defmodule Refactorex.Refactor.SelectionTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Selection

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

    assert {:ok,
            """



                            fn filename ->
                  file = File.read!("\#{filename}.\#{ext}")
                  String.split(file, "\\n")
                end

            """} = Selection.erase_outside_range(original, range)
  end
end
