defmodule Refactorex.Refactor.Function.CollapseAnonymousFunctionTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Function.CollapseAnonymousFunction

  test "collapses anonymous function from fn syntax to &" do
    assert_refactored(
      CollapseAnonymousFunction,
      """
      value = 10
      #                   v
      Enum.map(filenames, fn arg1 -> arg1 + value end)
      #                                             ^
      """,
      """
      value = 10
      Enum.map(filenames, &(&1 + value))
      """
    )
  end

  test "collapses anonymous function correctly replacing args" do
    assert_refactored(
      CollapseAnonymousFunction,
      """
      #                      v
      Enum.reduce(filenames, fn arg1, arg2 ->
        case arg1 do
          10 -> arg1 + arg2
          arg1 -> arg1 + arg2
        end
      end)
      # ^
      """,
      """
      Enum.reduce(
        filenames,
        &case &1 do
          10 -> &1 + &2
          arg1 -> arg1 + &2
        end
      )
      """
    )
  end

  test "ignores anonymous function with pattern matching" do
    assert_not_refactored(
      CollapseAnonymousFunction,
      """
      #                   v
      Enum.map(filenames, fn %{arg1: arg1} -> arg1 + 10 end)
      #                                                   ^
      """
    )
  end

  test "ignores anonymous function with multiples statements" do
    assert_not_refactored(
      CollapseAnonymousFunction,
      """
      #                   v
      Enum.map(filenames, fn arg1 ->
        arg2 = arg1 + 10
        arg2 * 25
      end)
      # ^
      """
    )
  end

  test "ignores anonymous function with multiples clauses" do
    assert_not_refactored(
      CollapseAnonymousFunction,
      """
      #                   v
      Enum.map(filenames, fn
        1 -> File.read!(arg1)
        arg1 -> File.read!(arg1)
      end)
      # ^
      """
    )
  end

  test "ignores anonymous function with zero args" do
    assert_not_refactored(
      CollapseAnonymousFunction,
      """
      def foo do
      # v
        fn -> nil end
      #             ^
      end
      """
    )
  end

  test "ignores anonymous function with unused args" do
    assert_not_refactored(
      CollapseAnonymousFunction,
      """
      def foo do
      # v
        fn _, foo -> foo end
      #                    ^
      end
      """
    )
  end
end
