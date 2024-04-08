defmodule Refactorex.Refactor.Function.OneLineTest do
  use ExUnit.Case

  alias Refactorex.Refactor.Function.OneLine

  test "refactors function to an one line function" do
    original =
      code("""
      defmodule Foo do
        def bar(arg) do
          arg
        end

        #      v
        def baz(arg1, arg2 \\\\ nil) do
          bar(arg1) + arg2
        end
      end
      """)

    refactored =
      code("""
      defmodule Foo do
        def bar(arg) do
          arg
        end

        #      v
        def baz(arg1, arg2 \\\\ nil), do: bar(arg1) + arg2
      end
      """)

    assert {refactored, true} == OneLine.refactor(original, %{line: 7, character: 10})
  end

  test "refactors function with zero arguments and no return " do
    original =
      code("""
      def baz do
      end
      # ^
      """)

    refactored =
      code("""
      def baz, do: nil
      # ^
      """)

    assert {refactored, true} == OneLine.refactor(original, %{line: 2, character: 3})
  end

  test "refactors function with a single multi line map" do
    original =
      code("""
      def baz do
        %{
          username: "gp-pereira",
          language: "pt-BR"
        }
        # ^
      end
      """)

    refactored =
      code("""
      def baz,
        do: %{
          username: "gp-pereira",
          language: "pt-BR"
        }

      # ^
      """)

    assert {refactored, true} == OneLine.refactor(original, %{line: 5, character: 3})
  end

  test "ignores multiple block functions " do
    original =
      code("""
      defmodule Foo do
        #    v
        def baz(arg) do
          arg
          arg + 1
        end
      end
      """)

    assert {original, false} == OneLine.refactor(original, %{line: 3, character: 8})
  end

  test "ignores already one line functions" do
    original =
      code("""
      defmodule Foo do
        #     v
        def baz(arg1), do: arg1
      end
      """)

    assert {original, false} == OneLine.refactor(original, %{line: 3, character: 8})
  end

  def code(code), do: String.trim(code)
end
