defmodule Refactorex.Refactor.Function.RegularSyntaxTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Function.RegularSyntax

  test "refactors keyword function with regular syntax" do
    assert_refactored(
      RegularSyntax,
      """
      defmodule Foo do
        #      v
        def baz(arg1, arg2 \\\\ nil), do: bar(arg1) + arg2
      end
      """,
      """
      defmodule Foo do
        #      v
        def baz(arg1, arg2 \\\\ nil) do
          bar(arg1) + arg2
        end
      end
      """
    )
  end

  test "refactors function with zero arguments and no return " do
    assert_refactored(
      RegularSyntax,
      """
      defmodule Foo do
        #      v
        def baz, do: nil
      end
      """,
      """
      defmodule Foo do
        #      v
        def baz do
          nil
        end
      end
      """
    )
  end

  test "ignores regular functions" do
    assert_not_refactored(
      RegularSyntax,
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
      RegularSyntax,
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
