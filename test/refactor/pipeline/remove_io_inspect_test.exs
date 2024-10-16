defmodule Refactorex.Refactor.Pipeline.RemoveIOInspectTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Pipeline.RemoveIOInspect

  test "removes the IO.inspect function call" do
    assert_refactored(
      RemoveIOInspect,
      """
      #        v
      IO.inspect(foo)
      """,
      """
      foo
      """
    )
  end

  test "removes IO.inspect function call with opts" do
    assert_refactored(
      RemoveIOInspect,
      """
      #        v
      IO.inspect(foo, opts: "foo: ")
      """,
      """
      foo
      """
    )
  end

  test "removes piped IO.inspect function call" do
    assert_refactored(
      RemoveIOInspect,
      """
      foo
      #        v
      |> IO.inspect()
      """,
      """
      foo
      """
    )
  end

  test "removes piped IO.inspect function call with opts" do
    assert_refactored(
      RemoveIOInspect,
      """
      foo
      #        v
      |> IO.inspect(label: "foo")
      """,
      """
      foo
      """
    )
  end

  test "removes piped IO.inspect function call in the middle of pipeline" do
    assert_refactored(
      RemoveIOInspect,
      """
      foo
      |> baz()
      #        v
      |> IO.inspect()
      |> bar()
      """,
      """
      foo
      |> baz()
      |> bar()
      """
    )
  end

  test "removes piped IO.inspect function call in the middle of pipeline with opts" do
    assert_refactored(
      RemoveIOInspect,
      """
      foo
      |> baz()
      #        v
      |> IO.inspect(label: "foo")
      |> bar()
      """,
      """
      foo
      |> baz()
      |> bar()
      """
    )
  end

  test "removes IO.inspect from anonymous function" do
    assert_refactored(
      RemoveIOInspect,
      """
      foo
      #        v
      |> then(&IO.inspect(baz(&1, 40)))
      |> bar()
      """,
      """
      foo
      |> then(&baz(&1, 40))
      |> bar()
      """
    )
  end

  test "removes IO.inspect from anonymous function with opts" do
    assert_refactored(
      RemoveIOInspect,
      """
      foo
      #        v
      |> then(&IO.inspect(baz(&1, 40), label: "baz(foo)"))
      |> bar()
      """,
      """
      foo
      |> then(&baz(&1, 40))
      |> bar()
      """
    )
  end

  test "removes IO.inspect from anonymous function with arity syntax" do
    assert_refactored(
      RemoveIOInspect,
      """
      foo
      #        v
      |> then(&IO.inspect/1)
      |> bar()
      """,
      """
      foo
      |> then(& &1)
      |> bar()
      """
    )
  end
end
