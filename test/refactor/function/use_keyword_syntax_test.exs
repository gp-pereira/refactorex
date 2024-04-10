defmodule Refactorex.Refactor.Function.UseKeywordSyntaxTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Function.UseKeywordSyntax

  test "refactors function with keyword syntax" do
    assert_refactored(
      UseKeywordSyntax,
      """
      defmodule Foo do
        def bar(arg) do
          arg
        end

        #      v
        def baz(arg1, arg2 \\\\ nil) do
          bar(arg1) + arg2
        end
      end
      """,
      """
      defmodule Foo do
        def bar(arg) do
          arg
        end

        #      v
        def baz(arg1, arg2 \\\\ nil), do: bar(arg1) + arg2
      end
      """
    )
  end

  test "refactors function with zero arguments and no return " do
    assert_refactored(
      UseKeywordSyntax,
      """
      #    v
      def baz do
      end
      """,
      """
      #    v
      def baz, do: nil
      """
    )
  end

  test "refactors function with a single multiline map" do
    assert_refactored(
      UseKeywordSyntax,
      """
      #    v
      def baz do
        %{
          username: "gp-pereira",
          language: "pt-BR"
        }
       end
      """,
      """
      #    v
      def baz,
        do: %{
          username: "gp-pereira",
          language: "pt-BR"
        }
      """
    )
  end

  test "refactors private function" do
    assert_refactored(
      UseKeywordSyntax,
      """
      defmodule Foo do
        #      v
        defp baz(arg) do
          arg
        end
      end
      """,
      """
      defmodule Foo do
        #      v
        defp baz(arg), do: arg
      end
      """
    )
  end

  test "ignores multiple block functions " do
    assert_not_refactored(
      UseKeywordSyntax,
      """
      defmodule Foo do
        #    v
        def baz(arg) do
          arg
          arg + 1
        end
      end
      """
    )
  end

  test "ignores keyword functions" do
    assert_not_refactored(
      UseKeywordSyntax,
      """
      defmodule Foo do
        #     v
        def baz(arg1), do: arg1
      end
      """
    )
  end

  test "ignores functions outside range" do
    assert_not_refactored(
      UseKeywordSyntax,
      """
      #      v
      defmodule Foo do
        def bar(arg) do
          arg
        end

        def bar(arg) do
          arg
        end
      end
      """
    )
  end
end
