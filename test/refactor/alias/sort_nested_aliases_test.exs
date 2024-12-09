defmodule Refactorex.Refactor.Alias.SortNestedAliasesTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Alias.SortNestedAliases

  test "sorts nested aliases alphabetically" do
    assert_refactored(
      SortNestedAliases,
      """
      #   v
      alias Foo.{
        B,
        C,
        A
      }
      """,
      """
      alias Foo.{
        A,
        B,
        C
      }
      """
    )
  end

  test "sorts nested aliases recursively" do
    assert_refactored(
      SortNestedAliases,
      """
      #   v
      alias Foo.{
        C,
        B.{
          E,
          F,
          D,
        },
        C.Bar,
        B,
        A.Foo.Delta,
        A.Foo,
        A
      }
      """,
      """
      alias Foo.{
        A,
        A.Foo,
        A.Foo.Delta,
        B,
        B.{
          D,
          E,
          F
        },
        C,
        C.Bar
      }
      """
    )
  end

  test "ignores alias without nesting" do
    assert_ignored(
      SortNestedAliases,
      """
      #   v
      alias Foo.Bar.Delta, as: K
      """
    )
  end

  test "ignores already sorted alias" do
    assert_ignored(
      SortNestedAliases,
      """
      #   v
      alias Foo.{
        A,
        B,
        C
      }
      """
    )
  end
end
