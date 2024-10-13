defmodule Refactorex.Refactor.Constant.RenameConstantTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Constant.RenameConstant

  test "renames the selected constant" do
    assert_refactored(
      RenameConstant,
      """
      defmodule Foo do
      #  v
        @foo %{status: "PAID"}
      #    ^
      end
      """,
      """
      defmodule Foo do
        @under_refactor11112023 %{status: "PAID"}
      end
      """
    )
  end
end
