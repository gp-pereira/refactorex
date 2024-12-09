defmodule Refactorex.Refactor.Variable.RenameVariableTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Variable.RenameVariable

  test "renames all usages when function arg is selected" do
    assert_refactored(
      RenameVariable,
      """
      #       v
      def bar(arg) do
      #         ^
        arg = arg + 10
      end
      """,
      """
      def bar(#{placeholder()}) do
        arg = #{placeholder()} + 10
      end
      """
    )
  end

  test "renames all usages when guard arg is selected" do
    assert_refactored(
      RenameVariable,
      """
      #             v
      defguardp bar(arg) when arg > 10
      #               ^
      """,
      """
      defguardp bar(#{placeholder()}) when #{placeholder()} > 10
      """
    )
  end

  test "renames all usages when variable assignment is selected" do
    assert_refactored(
      RenameVariable,
      """
      def bar(arg) do
      # v
        arg = arg + 10
      #   ^
        arg * 10
      end
      """,
      """
      def bar(arg) do
        #{placeholder()} = arg + 10
        #{placeholder()} * 10
      end
      """
    )
  end

  test "renames but do not modify the code structure" do
    assert_refactored(
      RenameVariable,
      """
      def bar(args) do
        #                   v
        args |> Enum.map(fn a -> a + 10 end) |> Enum.sum()
        #                   ^
      end
      """,
      """
      def bar(args) do
        args |> Enum.map(fn #{placeholder()} -> #{placeholder()} + 10 end) |> Enum.sum()
      end
      """
    )
  end

  test "renames the all usages until a new assignment" do
    assert_refactored(
      RenameVariable,
      """
      defmodule Foo do
        def foo(arg) do
          sum = arg + 5
      #     v
          {[sum], 10} = {arg + 4, 10}
      #       ^

          bar =
            case arg * sum do
              40 ->
                arg2 = arg - sum
                [%{sum: sum}] = [%{sum: arg2 + 10 - sum}]
                arg * sum

              30 ->
                sum
            end

          bar + sum
        end
      end
      """,
      """
      defmodule Foo do
        def foo(arg) do
          sum = arg + 5
          {[#{placeholder()}], 10} = {arg + 4, 10}

          bar =
            case arg * #{placeholder()} do
              40 ->
                arg2 = arg - #{placeholder()}
                [%{sum: sum}] = [%{sum: arg2 + 10 - #{placeholder()}}]
                arg * sum

              30 ->
                #{placeholder()}
            end

          bar + #{placeholder()}
        end
      end
      """
    )
  end

  test "renames all usages from variable assigned on CASE condition" do
    assert_refactored(
      RenameVariable,
      """
      defmodule Foo do
        def foo(arg) do
          sum = 20

      #        v
          case sum = arg + 10 do
      #          ^
            sum -> sum + 12
            10 -> sum + 10
          end
        end
      end
      """,
      """
      defmodule Foo do
        def foo(arg) do
          sum = 20

          case #{placeholder()} = arg + 10 do
            sum -> sum + 12
            10 -> #{placeholder()} + 10
          end
        end
      end
      """
    )
  end

  test "renames all usages from variable assigned on -> clause" do
    assert_refactored(
      RenameVariable,
      """
      defmodule Foo do
        def foo(arg) do
          sum = 20

          case arg do
      #            v
            %{sum: sum} -> sum + 12
      #              ^
            10 -> sum + 10
          end
        end
      end
      """,
      """
      defmodule Foo do
        def foo(arg) do
          sum = 20

          case arg do
            %{sum: #{placeholder()}} -> #{placeholder()} + 12
            10 -> sum + 10
          end
        end
      end
      """
    )
  end

  test "renames all usages from COND clauses" do
    assert_refactored(
      RenameVariable,
      """
      #                    v
      def at_one?(%{node: {id, _, nil}} = zipper) do
      #                     ^
        cond do
          id = compute_id() ->
            id != "me"

          not is_atom(id) ->
            id = 20
            id < 20

          true ->
            true
        end
      end
      """,
      """
      def at_one?(%{node: {#{placeholder()}, _, nil}} = zipper) do
        cond do
          id = compute_id() ->
            id != "me"

          not is_atom(#{placeholder()}) ->
            id = 20
            id < 20

          true ->
            true
        end
      end
      """
    )
  end

  test "does not rename constants and functions with the same name" do
    assert_refactored(
      RenameVariable,
      """
      defmodule Foo do
        @foo 42

        #       v
        def foo(foo) do
        #         ^
          foo + @foo + foo(foo)
        end
      end
      """,
      """
      defmodule Foo do
        @foo 42

        def foo(#{placeholder()}) do
          #{placeholder()} + @foo + foo(#{placeholder()})
        end
      end
      """
    )
  end

  test "ignores function call values" do
    assert_ignored(
      RenameVariable,
      """
      defp was_variable_reassigned?(node, name) do
        #                  v
        was_variable_used?(args, name)
        #                     ^
      end
      """
    )
  end

  test "ignores pinned variables" do
    assert_ignored(
      RenameVariable,
      """
      defp was_variable_reassigned?(node, name) do
        #    v
        fn {^args, _} -> name end
        #       ^
      end
      """
    )
  end

  # test "ignores variable usages inside WHEN clause" do
  #   assert_refactored(
  #     RenameVariable,
  #     """
  #     #                          v
  #     defp foo?(node, name) when node > name do
  #     #                             ^
  #       node
  #     end
  #     """,
  #     """
  #     defguardp bar(#{placeholder()}) when #{placeholder()} > 10
  #     """
  #   )
  # end
end
