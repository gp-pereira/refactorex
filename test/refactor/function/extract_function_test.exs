defmodule Refactorex.Refactor.Function.ExtractFunctionTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Function.ExtractFunction

  test "extracts selection into a private function" do
    assert_refactored(
      ExtractFunction,
      """
      defmodule Foo do
        def foo(a, b) do
      #   v
          a
          |> bar()
          |> baz(b)
      #           ^
        end
      end
      """,
      """
      defmodule Foo do
        def foo(a, b) do
          extracted_function(
            a,
            b
          )
        end

        defp extracted_function(a, b) do
          a
          |> bar()
          |> baz(b)
        end
      end
      """
    )
  end

  test "extracts function using a new unique name" do
    assert_refactored(
      ExtractFunction,
      """
      defmodule Foo do
        def foo(a) do
      #   v
          a
          |> bar()
      #          ^
        end

        def extracted_function(_), do: 1
        def extracted_function1(_), do: 2
      end
      """,
      """
      defmodule Foo do
        def foo(a) do
          extracted_function2(a)
        end

        def extracted_function(_), do: 1
        def extracted_function1(_), do: 2

        defp extracted_function2(a) do
          a
          |> bar()
        end
      end
      """
    )
  end

  test "extracts consecutive statements that are not the whole block" do
    assert_refactored(
      ExtractFunction,
      """
      defmodule Foo do
        def foo(a) do
          a = 10
      #   v
          b = 20
          a + b
      #       ^
          c = 30
        end
      end
      """,
      """
      defmodule Foo do
        def foo(a) do
          a = 10
          extracted_function(a)
          c = 30
        end

        defp extracted_function(a) do
          b = 20
          a + b
        end
      end
      """
    )
  end

  test "extracts function and recreates the last assignment " do
    assert_refactored(
      ExtractFunction,
      """
      defmodule Foo do
        def foo(a) do
      #   v
          a = a + 10
          b = a + 20
      #            ^
          c = b + 30
        end
      end
      """,
      """
      defmodule Foo do
        def foo(a) do
          b = extracted_function(a)
          c = b + 30
        end

        defp extracted_function(a) do
          a = a + 10
          a + 20
        end
      end
      """
    )

    assert_refactored(
      ExtractFunction,
      """
      defmodule Foo do
        def foo(a) do
      #   v
          b = a + 20
      #            ^
        end
      end
      """,
      """
      defmodule Foo do
        def foo(a) do
          b = extracted_function(a)
        end

        defp extracted_function(a) do
          a + 20
        end
      end
      """
    )
  end

  test "extracts part of a pipeline into function" do
    assert_refactored(
      ExtractFunction,
      """
      defmodule Foo do
        def foo(a, b) do
          a
          |> foo()
          #  v
          |> bar(b)
          |> quack(b)
          |> qez()
        #        ^
          |> baz()
        end
      end
      """,
      """
      defmodule Foo do
        def foo(a, b) do
          a
          |> foo()
          |> extracted_function(b)
          |> baz()
        end

        defp extracted_function(arg1, b) do
          arg1
          |> bar(b)
          |> quack(b)
          |> qez()
        end
      end
      """
    )
  end

  test "ignore with clauses" do
    assert_not_refactored(
      ExtractFunction,
      """
      defmodule Foo do
        def foo(arg) do
          #    v
          with {:ok, arg} <- format(arg) do
          #                            ^
            {:ok, arg}
          end
        end
      end
      """
    )
  end

  test "ignore module constants" do
    assert_not_refactored(
      ExtractFunction,
      """
      defmodule Foo do
        @bar 42

        def foo(arg) do
        # v
          @bar
        #    ^
        end
      end
      """
    )
  end

  test "ignore anonymous functions" do
    assert_not_refactored(
      ExtractFunction,
      """
      defmodule Foo do
        @bar 42

        def foo(arg) do
        #               v
          Enum.map(arg, &(&1 + 1))
        #                       ^
        end
      end
      """
    )
  end

  test "ignore variable declaration functions" do
    assert_not_refactored(
      ExtractFunction,
      """
      defmodule Foo do
        @bar 42

        #       v
        def foo(arg) do
        #         ^
          Enum.map(arg, &(&1 + 1))
        end
      end
      """
    )
  end

  test "ignores alias" do
    assert_not_refactored(
      ExtractFunction,
      """
      defmodule Foo do
      # v
        alias Foo.Bar
      #             ^
      end
      """
    )
  end
end
