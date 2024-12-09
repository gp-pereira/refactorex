defmodule Refactorex.Refactor.Function.RenameFunctionTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Function.RenameFunction

  test "renames the selected private function definition and usages" do
    assert_refactored(
      RenameFunction,
      """
      defmodule Foo do
        #                 v
        def foo(arg), do: bar(arg)
        #                   ^

        defp bar(arg) do
          (arg + 10)
          |> bar()
        end
      end
      """,
      """
      defmodule Foo do
        def foo(arg), do: #{placeholder()}(arg)

        defp #{placeholder()}(arg) do
          (arg + 10)
          |> #{placeholder()}()
        end
      end
      """
    )
  end

  test "renames the selected public function definition and usages" do
    assert_refactored(
      RenameFunction,
      """
      defmodule Foo do
        #                 v
        def foo(arg), do: bar(arg)
        #                   ^

        def bar(arg), do: arg + 10
      end
      """,
      """
      defmodule Foo do
        def foo(arg), do: #{placeholder()}(arg)

        def #{placeholder()}(arg), do: arg + 10
      end
      """
    )
  end

  test "renames the selected public function with multiple definitions" do
    assert_refactored(
      RenameFunction,
      """
      defmodule Foo do
        #                 v
        def foo(arg), do: bar(arg)
        #                   ^

        def bar(arg)
        def bar(arg) when is_number(arg), do: arg + 10
        def bar(%{value: value}), do: value + 10
      end
      """,
      """
      defmodule Foo do
        def foo(arg), do: #{placeholder()}(arg)

        def #{placeholder()}(arg)
        def #{placeholder()}(arg) when is_number(arg), do: arg + 10
        def #{placeholder()}(%{value: value}), do: value + 10
      end
      """
    )
  end

  test "renames the selected public function with default args" do
    assert_refactored(
      RenameFunction,
      """
      defmodule Foo do
        #                 v
        def foo(arg), do: bar(arg, arg)
        #                   ^

        def bar(arg1 \\\\ 4, arg2 \\\\ nil), do: arg1 + arg2
      end
      """,
      """
      defmodule Foo do
        def foo(arg), do: #{placeholder()}(arg, arg)

        def #{placeholder()}(arg1 \\\\ 4, arg2 \\\\ nil), do: arg1 + arg2
      end
      """
    )
  end

  test "renames the selected function even when piped" do
    assert_refactored(
      RenameFunction,
      """
      defmodule Foo do
        #                        v
        def foo(arg), do: arg |> bar(arg)
        #                          ^

        defp bar(arg1, arg2)
        defp bar(arg1, arg2), do: arg1 + arg2
        defp bar(arg1, arg2), do: arg1 - arg2
      end
      """,
      """
      defmodule Foo do
        def foo(arg), do: arg |> #{placeholder()}(arg)

        defp #{placeholder()}(arg1, arg2)
        defp #{placeholder()}(arg1, arg2), do: arg1 + arg2
        defp #{placeholder()}(arg1, arg2), do: arg1 - arg2
      end
      """
    )
  end

  test "renames the selected arity-syntax function" do
    assert_refactored(
      RenameFunction,
      """
      defmodule Foo do
        def foo(args) do
        #                 v
          Enum.map(args, &bar/1)
        #                   ^
        end

        defp bar(arg), do: arg + 10
      end
      """,
      """
      defmodule Foo do
        def foo(args) do
          Enum.map(args, &#{placeholder()}/1)
        end

        defp #{placeholder()}(arg), do: arg + 10
      end
      """
    )
  end

  test "renames only affect the current module" do
    assert_refactored(
      RenameFunction,
      """
      defmodule Before do
        def foo(args) do
          Enum.map(args, &bar/1)
        end

        defp bar(arg), do: arg + 10
      end

      defmodule Foo do
        def foo(args) do
        #                 v
          Enum.map(args, &bar/1)
        #                   ^
        end

        defp bar(arg), do: arg + 10
      end

      defmodule After do
        def foo(args) do
          Enum.map(args, &bar/1)
        end

        defp bar(arg), do: arg + 10
      end
      """,
      """
      defmodule Before do
        def foo(args) do
          Enum.map(args, &bar/1)
        end

        defp bar(arg), do: arg + 10
      end

      defmodule Foo do
        def foo(args) do
          Enum.map(args, &#{placeholder()}/1)
        end

        defp #{placeholder()}(arg), do: arg + 10
      end

      defmodule After do
        def foo(args) do
          Enum.map(args, &bar/1)
        end

        defp bar(arg), do: arg + 10
      end
      """
    )
  end

  test "ignores function when the definition cannot be found" do
    assert_ignored(
      RenameFunction,
      """
      defmodule Foo do
        def foo(arg) do
        # v
          bar(arg)
        #   ^
        end
      end
      """
    )
  end

  test "ignores selection outside module" do
    assert_ignored(
      RenameFunction,
      """
      def foo(arg) do
      # v
        bar(arg)
      #   ^
      end
      """
    )
  end
end
