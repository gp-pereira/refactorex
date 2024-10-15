defmodule Refactorex.Refactor.IfElse.UseKeywordSyntaxTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.IfElse.UseKeywordSyntax

  test "refactors if statement with keyword syntax" do
    assert_refactored(
      UseKeywordSyntax,
      """
      # v
      if true do
        bar
      end
      """,
      """
      if true, do: bar
      """
    )
  end

  test "refactors if else statement with keyword syntax" do
    assert_refactored(
      UseKeywordSyntax,
      """
      # v
      if true do
        bar
      else
        bar + 10
      end
      """,
      """
      if true,
        do: bar,
        else: bar + 10
      """
    )
  end

  test "ignores if statement with multiple inner statements" do
    assert_not_refactored(
      UseKeywordSyntax,
      """
      # v
      if true do
        bar + 10
        bar + 20
      end
      """
    )
  end

  test "ignores if else statement with multiple inner statements" do
    assert_not_refactored(
      UseKeywordSyntax,
      """
      # v
      if true do
        bar + 10
      else
        bar + 20
        bar + 40
      end
      """
    )
  end

  test "ignores if else statement already with keyword syntax" do
    assert_not_refactored(
      UseKeywordSyntax,
      """
      # v
      if true, do: bar
      """
    )
  end
end
