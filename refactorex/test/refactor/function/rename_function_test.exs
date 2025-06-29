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

  test "renames the zero arity function definition and usages" do
    assert_refactored(
      RenameFunction,
      """
      defmodule Foo do
        def foo(arg), do: bar()

        #   v
        def bar, do: 10 + 10
        #     ^
      end
      """,
      """
      defmodule Foo do
        def foo(arg), do: #{placeholder()}()

        def #{placeholder()}, do: 10 + 10
      end
      """
    )
  end

  test "renames function with default args" do
    assert_refactored(
      RenameFunction,
      """
      defmodule Foo do
        def foo(arg) do
        # v
          bar()
        #   ^
          bar(10)
        end

        def bar(arg \\\\ 10), do: arg + 10
      end
      """,
      """
      defmodule Foo do
        def foo(arg) do
          #{placeholder()}()
          #{placeholder()}(10)
        end

        def #{placeholder()}(arg \\\\ 10), do: arg + 10
      end
      """
    )
  end

  test "renames function call followed by pipe" do
    assert_refactored(
      RenameFunction,
      """
      defmodule Foo do
        def foo() do
        # v
          extracted_function(zipper, aliases)
        #                  ^
          |> IO.inspect()
        end

        def extracted_function(a, b) do
        end
      end
      """,
      """
      defmodule Foo do
        def foo() do
          #{placeholder()}(zipper, aliases)
          |> IO.inspect()
        end

        def #{placeholder()}(a, b) do
        end
      end
      """
    )
  end

  test "renames collapsed anonymous function" do
    assert_refactored(
      RenameFunction,
      """
      defmodule Foo do
        #   v
        def foo() do
        #     ^
          &foo/0
          &foo/1
        end
      end
      """,
      """
      defmodule Foo do
        def #{placeholder()}() do
          &#{placeholder()}/0
          &foo/1
        end
      end
      """
    )
  end

  test "renames function called from __MODULE__" do
    assert_refactored(
      RenameFunction,
      """
      defmodule Foo do
        def foo() do
        #            v
          __MODULE__.foo()
        #              ^
          __MODULE__.foo(10)
          &__MODULE__.foo/0
          &__MODULE__.foo/1
          &__MODULE__.foo()
        end
      end
      """,
      """
      defmodule Foo do
        def #{placeholder()}() do
          __MODULE__.#{placeholder()}()
          __MODULE__.foo(10)
          &__MODULE__.#{placeholder()}/0
          &__MODULE__.foo/1
          &__MODULE__.#{placeholder()}()
        end
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
