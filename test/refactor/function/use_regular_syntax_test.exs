defmodule Refactorex.Refactor.Function.UseRegularSyntaxTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Function.UseRegularSyntax

  test "refactors keyword function with regular syntax" do
    assert_refactored(
      UseRegularSyntax,
      """
      defmodule Foo do
        #      v
        def baz(arg1, arg2 \\\\ nil), do: bar(arg1) + arg2
      end
      """,
      """
      defmodule Foo do
        def baz(arg1, arg2 \\\\ nil) do
          bar(arg1) + arg2
        end
      end
      """
    )
  end

  test "refactors function with zero arguments and no return " do
    assert_refactored(
      UseRegularSyntax,
      """
      defmodule Foo do
        #      v
        def baz, do: nil
      end
      """,
      """
      defmodule Foo do
        def baz do
          nil
        end
      end
      """
    )
  end

  test "refactors private function" do
    assert_refactored(
      UseRegularSyntax,
      """
      defmodule Foo do
        #      v
        defp baz, do: nil
      end
      """,
      """
      defmodule Foo do
        defp baz do
          nil
        end
      end
      """
    )
  end

  test "ignores regular functions" do
    assert_not_refactored(
      UseRegularSyntax,
      """
      defmodule Foo do
        #     v
        def baz(arg1) do
          arg1
        end
      end
      """
    )
  end

  test "ignores functions outside range" do
    assert_not_refactored(
      UseRegularSyntax,
      """
      defmodule Foo do
        def bar(arg), do: arg

        def baz(arg),
          do: %{
            username: "gp-pereira",
            language: "pt-BR"
          }

        # v
      end
      """
    )
  end
end
