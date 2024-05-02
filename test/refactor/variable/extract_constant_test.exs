defmodule Refactorex.Refactor.Variable.ExtractConstantTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Variable.ExtractConstant

  test "extracts selection range into a module constant" do
    assert_refactored(
      ExtractConstant,
      """
      defmodule Foo do
      #                v
        @foo %{status: "PAID"}
      #                     ^
      end
      """,
      """
      defmodule Foo do
        @extracted_constant "PAID"
        @foo %{status: @extracted_constant}
      end
      """
    )
  end

  test "extracts zero arg function into constant" do
    assert_refactored(
      ExtractConstant,
      """
      defmodule Foo do
        def foo(arg) do
        # v
          bar()
        #     ^
        end
      end
      """,
      """
      defmodule Foo do
        @extracted_constant bar()
        def foo(arg) do
          @extracted_constant
        end
      end
      """
    )
  end

  test "extracts node that uses other constants" do
    assert_refactored(
      ExtractConstant,
      """
      defmodule Foo do
        @first_constant 10
        #                         v
        @second_constant %{range: %{start: @first_constant, end: 14}}
        #                                                          ^
      end
      """,
      """
      defmodule Foo do
        @first_constant 10
        @extracted_constant %{start: @first_constant, end: 14}
        @second_constant %{range: @extracted_constant}
      end
      """
    )
  end

  test "extracts multiline selection into constant" do
    assert_refactored(
      ExtractConstant,
      """
      defmodule Foo do
        def foo do
        # v
          :foo
          |> bar()
          |> baz()
        #        ^
        end
      end
      """,
      """
      defmodule Foo do
        @extracted_constant :foo
                            |> bar()
                            |> baz()
        def foo do
          @extracted_constant
        end
      end
      """
    )
  end

  test "extracts constant after some reserved keywords" do
    assert_refactored(
      ExtractConstant,
      """
      defmodule Foo do
        use Bar
        alias Bar
        import Bar
        require Logger

        @behaviour Baz

        def foo(arg) do
        # v
          bar()
        #     ^
        end
      end
      """,
      """
      defmodule Foo do
        use Bar
        alias Bar
        import Bar
        require Logger

        @behaviour Baz

        @extracted_constant bar()
        def foo(arg) do
          @extracted_constant
        end
      end
      """
    )
  end

  test "ignores constants" do
    assert_not_refactored(
      ExtractConstant,
      """
      defmodule Foo do
        @other_constant 10

        def foo(arg) do
        # v
          @other_constant
        #               ^
          |> bar()
        end
      end
      """
    )
  end

  test "ignores selection ranges with variables" do
    assert_not_refactored(
      ExtractConstant,
      """
      defmodule Foo do
        def foo(arg) do
        # v
          bar(arg)
        #        ^
        end
      end
      """
    )
  end

  test "ignores selection ranges outside modules" do
    assert_not_refactored(
      ExtractConstant,
      """
      #               v
      foo = %{status: "PAID"}
      #                    ^
      """
    )
  end
end
