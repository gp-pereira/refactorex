defmodule Refactorex.Refactor.Function.InlineFunctionTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Function.InlineFunction

  test "inlines the regular syntax function call" do
    assert_refactored(
      InlineFunction,
      """
      defmodule Foo do
        def foo(arg) do
          a = 10

        # v
          bar(arg)
        #        ^

          b = 10
        end

        defp bar(arg) do
          c = arg + 10
          c * 10
        end
      end
      """,
      """
      defmodule Foo do
        def foo(arg) do
          a = 10

          c = arg + 10
          c * 10
          b = 10
        end

        defp bar(arg) do
          c = arg + 10
          c * 10
        end
      end
      """
    )
  end

  test "inlines the keyword syntax function call" do
    assert_refactored(
      InlineFunction,
      """
      defmodule Foo do
        def foo(arg) do
          a = 10

        # v
          bar(arg)
        #        ^

          b = 10
        end

        defp bar(arg), do: arg + 10
      end
      """,
      """
      defmodule Foo do
        def foo(arg) do
          a = 10

          arg + 10
          b = 10
        end

        defp bar(arg), do: arg + 10
      end
      """
    )
  end

  test "inlines the multiple statements function call inside keyword syntax function" do
    assert_refactored(
      InlineFunction,
      """
      defmodule Foo do
        #                 v
        def foo(arg), do: bar(arg)
        #                        ^

        defp bar(arg) do
          c = arg + 10
          c * 10
        end
      end
      """,
      """
      defmodule Foo do
        def foo(arg) do
          c = arg + 10
          c * 10
        end

        defp bar(arg) do
          c = arg + 10
          c * 10
        end
      end
      """
    )
  end

  test "inlines the multiple statements function call inside another function call" do
    assert_refactored(
      InlineFunction,
      """
      defmodule Foo do
        #                            v
        def foo(arg), do: other_call(bar(arg))
        #                                   ^

        defp bar(arg) do
          c = arg + 10
          c * 10
        end
      end
      """,
      """
      defmodule Foo do
        def foo(arg) do
          c = arg + 10
          other_call(c * 10)
        end

        defp bar(arg) do
          c = arg + 10
          c * 10
        end
      end
      """
    )
  end

  test "inlines the function call correctly remapping args to call values" do
    assert_refactored(
      InlineFunction,
      """
      defmodule Foo do
        #                        v
        def foo(arg1, arg2), do: bar(arg1, arg2)
        #                                      ^

        defp bar(a, b) do
          c = b + a
          b = c * a
          a + b + c
        end
      end
      """,
      """
      defmodule Foo do
        def foo(arg1, arg2) do
          c = arg2 + arg1
          b = c * arg1
          arg1 + b + c
        end

        defp bar(a, b) do
          c = b + a
          b = c * a
          a + b + c
        end
      end
      """
    )
  end

  test "inlines the function call inside list" do
    assert_refactored(
      InlineFunction,
      """
      defmodule Foo do
        #                               v
        def foo(arg1, arg2), do: %{bar: bar(arg1, arg2)}
        #                                             ^

        defp bar(a, b) do
          c = b + a
          b = c * a
          a + b + c
        end
      end
      """,
      """
      defmodule Foo do
        def foo(arg1, arg2) do
          c = arg2 + arg1
          b = c * arg1
          %{bar: arg1 + b + c}
        end

        defp bar(a, b) do
          c = b + a
          b = c * a
          a + b + c
        end
      end
      """
    )
  end

  test "inlines function call with single pattern matched definition" do
    assert_refactored(
      InlineFunction,
      """
      defmodule Foo do
        def foo(arg) do
        # v
          bar(arg, arg)
        #             ^
        end

        def bar(%{arg: arg}, _), do: arg
      end
      """,
      """
      defmodule Foo do
        def foo(arg) do
          {%{arg: arg}, _} = {arg, arg}
          arg
        end

        def bar(%{arg: arg}, _), do: arg
      end
      """
    )
  end

  test "inlines function call with single guarded definition as CASE statement" do
    assert_refactored(
      InlineFunction,
      """
      defmodule Foo do
        def foo(arg) do
        # v
          bar(arg, arg)
        #             ^
        end

        def bar(arg, _) when a < 10, do: arg
      end
      """,
      """
      defmodule Foo do
        def foo(arg) do
          case {arg, arg} do
            {arg, _} when a < 10 -> arg
          end
        end

        def bar(arg, _) when a < 10, do: arg
      end
      """
    )
  end

  test "inlines function call with multiple definitions as a CASE statement" do
    assert_refactored(
      InlineFunction,
      """
      defmodule Foo do
        def foo(arg) do
        # v
          bar(arg, arg)
        #             ^
        end

        def bar(%{arg: arg}, _), do: arg

        def bar(arg1, arg2) when arg1 + arg2 < 10, do: arg1 / arg2

        def bar(arg1, arg2) do
          c = arg1 + 10
          c * arg2
        end
      end
      """,
      """
      defmodule Foo do
        def foo(arg) do
          case {arg, arg} do
            {%{arg: arg}, _} ->
              arg

            {arg1, arg2} when arg1 + arg2 < 10 ->
              arg1 / arg2

            {arg1, arg2} ->
              c = arg1 + 10
              c * arg2
          end
        end

        def bar(%{arg: arg}, _), do: arg

        def bar(arg1, arg2) when arg1 + arg2 < 10, do: arg1 / arg2

        def bar(arg1, arg2) do
          c = arg1 + 10
          c * arg2
        end
      end
      """
    )
  end

  test "ignores function definition" do
    assert_not_refactored(
      InlineFunction,
      """
      defmodule Foo do
        def foo(arg) do
          bar(arg)
        end

        #   v
        def bar(arg), do: arg
        #          ^
      end
      """
    )
  end

  test "ignores function call without same module definition" do
    assert_not_refactored(
      InlineFunction,
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

  test "ignores function call inside pipeline" do
    assert_not_refactored(
      InlineFunction,
      """
      defmodule Foo do
        def foo(arg) do
        #        v
          arg |> bar()
        #            ^
        end

        def bar(arg), do: arg + 10
      end
      """
    )
  end

  test "ignores function call outside module" do
    assert_not_refactored(
      InlineFunction,
      """
      def foo(arg) do
      # v
        bar(arg)
      #        ^
      end
      """
    )
  end

  test "ignores captured function call" do
    assert_not_refactored(
      InlineFunction,
      """
      defmodule Foo do
        def foo(args) do
        #                 v
          Enum.map(args, &bar(&1))
        #                       ^
        end

        def bar(arg), do: arg
      end
      """
    )

    assert_not_refactored(
      InlineFunction,
      """
      defmodule Foo do
        def foo(args) do
        #                v
          Enum.map(args, &bar(&1))
        #                       ^
        end

        def bar(arg), do: arg
      end
      """
    )

    assert_not_refactored(
      InlineFunction,
      """
      defmodule Foo do
        def foo(args) do
        #                v
          Enum.map(args, &bar/1)
        #                     ^
        end

        def bar(arg), do: arg
      end
      """
    )
  end
end
