defmodule Refactorex.Refactor.Constant.RenameConstantTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Constant.RenameConstant

  test "renames all usages when constant definition is selected" do
    assert_refactored(
      RenameConstant,
      """
      defmodule Foo do
      #  v
        @foo 42
      #    ^

        def bar(a \\\\ @foo) do
          @foo
        end
      end
      """,
      """
      defmodule Foo do
        @#{placeholder()} 42

        def bar(a \\\\ @#{placeholder()}) do
          @#{placeholder()}
        end
      end
      """
    )
  end

  test "renames all usages when a constant usage is selected" do
    assert_refactored(
      RenameConstant,
      """
      defmodule Foo do
        @foo 42

        def foo(foo) do
          #      v
          foo + @foo
          #        ^
        end
      end
      """,
      """
      defmodule Foo do
        @#{placeholder()} 42

        def foo(foo) do
          foo + @#{placeholder()}
        end
      end
      """
    )
  end

  test "renames all usages when the selection includes the @" do
    assert_refactored(
      RenameConstant,
      """
      defmodule Foo do
        @foo 42

        def foo(foo) do
          #     v
          foo + @foo
          #        ^
        end
      end
      """,
      """
      defmodule Foo do
        @#{placeholder()} 42

        def foo(foo) do
          foo + @#{placeholder()}
        end
      end
      """
    )
  end

  test "does not rename variables and functions with the same name" do
    assert_refactored(
      RenameConstant,
      """
      defmodule Foo do
      #  v
        @foo 42
      #    ^

        def foo(foo) do
          foo + @foo
        end
      end
      """,
      """
      defmodule Foo do
        @#{placeholder()} 42

        def foo(foo) do
          foo + @#{placeholder()}
        end
      end
      """
    )
  end

  test "ignores variables" do
    assert_not_refactored(
      RenameConstant,
      """
      defmodule Foo do
        @foo 42

        def foo(foo) do
        # v
          foo + @foo
        #   ^
        end
      end
      """
    )
  end
end
