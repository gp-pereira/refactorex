defmodule Refactorex.Refactor.Variable.ExtractVariableTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Variable.ExtractVariable

  test "extracts the selection into a variable" do
    assert_refactored(
      ExtractVariable,
      """
      arg = 10
      #   v
      foo(arg.test)
      #          ^
      """,
      """
      arg = 10
      extracted_variable = arg.test
      foo(extracted_variable)
      """
    )
  end

  test "extracts a variable using an unique name" do
    assert_refactored(
      ExtractVariable,
      """
      def foo() do
        arg = 10
        extracted_variable = arg.test
        #   v
        foo(arg.test)
        #          ^
      end
      """,
      """
      def foo() do
        arg = 10
        extracted_variable = arg.test
        extracted_variable2 = arg.test
        foo(extracted_variable2)
      end
      """
    )
  end

  test "extracts variable inside single statement anonymous function" do
    assert_refactored(
      ExtractVariable,
      """
      def foo(arg) do
        arg
        #                     v
        |> Enum.map(fn arg -> arg + 10 end)
        #                       ^
      end
      """,
      """
      def foo(arg) do
        arg
        |> Enum.map(fn arg ->
          extracted_variable = arg
          extracted_variable + 10
        end)
      end
      """
    )
  end

  test "extracts variable inside multiple statements anonymous function" do
    assert_refactored(
      ExtractVariable,
      """
      def foo(arg) do
        arg
        |> Enum.map(fn arg ->
          arg = arg + 10
          #     v
          arg = arg + 20
          #       ^
        end)
      end
      """,
      """
      def foo(arg) do
        arg
        |> Enum.map(fn arg ->
          arg = arg + 10
          extracted_variable = arg
          arg = extracted_variable + 20
        end)
      end
      """
    )
  end

  test "extracts variable inside single statement function" do
    assert_refactored(
      ExtractVariable,
      """
      def foo(arg) do
      #       v
        arg + 20
      #        ^
      end
      """,
      """
      def foo(arg) do
        extracted_variable = 20
        arg + extracted_variable
      end
      """
    )
  end

  test "expands anonymous function before extracting variable" do
    assert_refactored(
      ExtractVariable,
      """
      def foo(module) do
        modules
        #                   v
        |> Stream.map(&{&1, &1.available?(zipper, selection_or_line)})
        #                                                          ^
      end
      """,
      """
       def foo(module) do
        modules
        |> Stream.map(fn arg1 ->
          extracted_variable = arg1.available?(zipper, selection_or_line)
          {arg1, extracted_variable}
        end)
      end
      """
    )
  end

  test "rewrites function using keyword syntax before extracting variable" do
    assert_refactored(
      ExtractVariable,
      """
      #                                     v
      def foo(arg) when arg < 20, do: arg + 10
      #                                      ^
      """,
      """
      def foo(arg) when arg < 20 do
        extracted_variable = 10
        arg + extracted_variable
      end
      """
    )
  end

  test "rewrites if else using keyword syntax before extracting variable" do
    assert_refactored(
      ExtractVariable,
      """
      #                                      v
      if foo(arg), do: arg + 10, else: arg + 20
      #                                       ^
      """,
      """
      if foo(arg) do
        arg + 10
      else
        extracted_variable = 20
        arg + extracted_variable
      end
      """
    )
  end

  test "extracts variable that is the whole block" do
    assert_refactored(
      ExtractVariable,
      """
      cond do
        true ->
        # v
          arg
        #   ^

        _ ->
          arg + 10
      end
      """,
      """
      cond do
        true ->
          extracted_variable = arg
          extracted_variable

        _ ->
          arg + 10
      end
      """,
      raw: true
    )
  end

  test "ignores variable declarations" do
    assert_not_refactored(
      ExtractVariable,
      """
      quote do
      # v
        arg = 10
      #   ^
        foo(arg.test)
      end
      """
    )
  end

  test "ignores part of pipeline" do
    assert_not_refactored(
      ExtractVariable,
      """
      quote do
        zipper
        #  v
        |> module.execute(selection_or_line)
        #                                  ^
        |> module.refactoring()
      end
      """
    )
  end
end
