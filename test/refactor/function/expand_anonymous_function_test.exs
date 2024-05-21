defmodule Refactorex.Refactor.Function.ExpandAnonymousFunctionTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Function.ExpandAnonymousFunction

  test "expands anonymous function from & to fn syntax" do
    assert_refactored(
      ExpandAnonymousFunction,
      """
      filenames
      #           v
      |> Enum.map(&File.read!(&1))
      #                         ^
      """,
      """
      filenames
      |> Enum.map(fn arg1 -> File.read!(arg1) end)
      """
    )
  end

  test "expands anonymous function with &/args to fn syntax" do
    assert_refactored(
      ExpandAnonymousFunction,
      """
      filenames
      #              v
      |> Enum.reduce(&Reader.read/2)
      #                           ^
      """,
      """
      filenames
      |> Enum.reduce(fn arg1, arg2 -> Reader.read(arg1, arg2) end)
      """
    )
  end

  test "expands anonymous function with zero arguments" do
    assert_refactored(
      ExpandAnonymousFunction,
      """

      #     v
      query(&connection/0)
      #                 ^
      """,
      """
      query(fn -> connection() end)
      """
    )
  end
end
