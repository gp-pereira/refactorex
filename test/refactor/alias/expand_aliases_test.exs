defmodule Refactorex.Refactor.Alias.ExpandAliasesTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Alias.ExpandAliases

  test "expands the selected nested alias" do
    assert_refactored(
      ExpandAliases,
      """
      defmodule Foo do
        #          v
        alias Qez.{Bar, Delta}
        #            ^
      end
      """,
      """
      defmodule Foo do
        alias Qez.{Delta}
        alias Qez.Bar
      end
      """
    )
  end

  test "expands the selected single nested alias" do
    assert_refactored(
      ExpandAliases,
      """
      defmodule Foo do
        #          v
        alias Qez.{Bar}
        #            ^
      end
      """,
      """
      defmodule Foo do
        alias Qez.Bar
      end
      """
    )
  end

  test "expands the selected single deeply nested  alias" do
    assert_refactored(
      ExpandAliases,
      """
      defmodule Foo do
        alias Qez.{
          Alpha,
        #        v
          Delta.{Bar}
        #          ^
        }
      end
      """,
      """
      defmodule Foo do
        alias Qez.{
          Alpha
        }

        alias Qez.Delta.Bar
      end
      """
    )
  end

  test "expands the selected multiple nested alias" do
    assert_refactored(
      ExpandAliases,
      """
      defmodule Foo do
        alias Qez.{
          Alpha,
        # v
          Delta.{Bar, Test.{A, B}, Foo}
        #                             ^
        }
      end
      """,
      """
      defmodule Foo do
        alias Qez.{
          Alpha
        }

        alias Qez.Delta.Bar
        alias Qez.Delta.Test.A
        alias Qez.Delta.Test.B
        alias Qez.Delta.Foo
      end
      """
    )
  end

  test "expands the whole selected alias" do
    assert_refactored(
      ExpandAliases,
      """
      defmodule Foo do
      # v
        alias Qez.{
          Alpha,
          Delta.{Bar, Test}
        }
      # ^
      end
      """,
      """
      defmodule Foo do
        alias Qez.Alpha
        alias Qez.Delta.Bar
        alias Qez.Delta.Test
      end
      """
    )
  end

  test "ignores outside module" do
    assert_ignored(
      ExpandAliases,
      """
      #          v
      alias Foo.{Bar}
      #            ^
      """
    )
  end

  test "ignores outside alias" do
    assert_ignored(
      ExpandAliases,
      """
      defmodule Foo do
        def foo() do
          #    v
          Foo.{Bar}
          #      ^
        end
      end
      """
    )
  end
end
