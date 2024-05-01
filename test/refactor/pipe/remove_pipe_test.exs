defmodule Refactorex.Refactor.Pipe.RemovePipeTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Pipe.RemovePipe

  test "removes pipe operator" do
    assert_refactored(
      RemovePipe,
      """
      #        v
      arg1 |> foo(arg2)
      """,
      """
      foo(arg1, arg2)
      """
    )
  end

  test "ignores range without pipes" do
    assert_not_refactored(
      RemovePipe,
      """
      def foo(arg1) do
        # v
        foo(arg1, 10)
      end
      """
    )
  end

  test "ignores range outside pipe usage" do
    assert_not_refactored(
      RemovePipe,
      """
      # v
      def foo(arg1) do
        arg1 |> foo(@arg2)
      end
      """
    )
  end
end
