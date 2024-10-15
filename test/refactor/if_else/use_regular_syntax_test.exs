defmodule Refactorex.Refactor.IfElse.UseRegularSyntaxTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.IfElse.UseRegularSyntax

  test "refactors if statement with regular syntax" do
    assert_refactored(
      UseRegularSyntax,
      """
      # v
      if true, do: bar
      """,
      """
      if true do
        bar
      end
      """
    )
  end

  test "refactors if else statement with regular syntax" do
    assert_refactored(
      UseRegularSyntax,
      """
      # v
      if true,
        do: bar,
        else: bar + 10
      """,
      """
      if true do
        bar
      else
        bar + 10
      end
      """
    )
  end

  test "ignores if else statement already with regular syntax" do
    assert_not_refactored(
      UseRegularSyntax,
      """
      # v
      if true do
        bar
      else
        bar + 10
      end
      """
    )
  end
end
