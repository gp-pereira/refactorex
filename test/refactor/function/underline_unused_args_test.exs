defmodule Refactorex.Refactor.Function.UnderlineUnusedArgsTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Function.UnderlineUnusedArgs

  test "underlines unused args on function header" do
    assert_refactored(
      UnderlineUnusedArgs,
      """
      #       v
      def foo(bar1, bar2, bar3) do
        bar1
      end
      """,
      """
      def foo(bar1, _bar2, _bar3) do
        bar1
      end
      """
    )
  end

  test "underlines unused args on anonymous function" do
    assert_refactored(
      UnderlineUnusedArgs,
      """
      fn
      #       v
        %{bar1: bar1, bar2: bar2} -> bar1
      end
      """,
      """
      fn
        %{bar1: bar1, bar2: _bar2} -> bar1
      end
      """
    )
  end

  test "underlines unused args inside pattern matching" do
    assert_refactored(
      UnderlineUnusedArgs,
      """
      #       v
      def foo(%{bar1: bar1, bar2: bar2}) do
        bar1
      end
      """,
      """
      def foo(%{bar1: bar1, bar2: _bar2}) do
        bar1
      end
      """
    )
  end

  test "ignores repeated args used for pattern matching" do
    assert_not_refactored(
      UnderlineUnusedArgs,
      """
      #       v
      def foo(bar1, bar2, bar2) do
        bar1
      end
      """
    )
  end

  test "ignores already underlined args" do
    assert_not_refactored(
      UnderlineUnusedArgs,
      """
      #       v
      def foo(bar1, _bar2) do
        bar1
      end
      """
    )
  end

  test "ignores pinned args" do
    assert_not_refactored(
      UnderlineUnusedArgs,
      """
      def foo(bar) do
        #       v
        fn %{bar: ^bar} -> :stop end
      end
      """
    )
  end

  test "ignores args used on guards" do
    assert_not_refactored(
      UnderlineUnusedArgs,
      """
      #       v
      def foo(bar1, bar2) when bar2 == 2 do
        bar1
      end
      """
    )
  end

  test "ignores range if it's not empty" do
    assert_not_refactored(
      UnderlineUnusedArgs,
      """
      #       v
      def foo(bar1, bar2, bar3) do
      #               ^
        bar1
      end
      """
    )
  end
end
