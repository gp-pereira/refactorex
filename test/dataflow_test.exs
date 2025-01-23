defmodule Refactorex.DataflowTest do
  use ExUnit.Case

  alias Refactorex.Dataflow

  defmacrop variable_at(name, line, column) do
    quote do
      {unquote(name),
       [
         trailing_comments: [],
         leading_comments: [],
         line: unquote(line),
         column: unquote(column)
       ], nil}
    end
  end

  test "lists all variables inside simple function with constants" do
    assert %{
             variable_at(:arg1, 1, 9) => [
               variable_at(:arg1, 2, 10)
             ],
             variable_at(:arg2, 1, 15) => [
               variable_at(:arg2, 2, 3)
             ]
           } =
             Dataflow.analyze(
               """
               def bar(arg1, arg2 \\\\ @arg2) do
                 arg2 + arg1 + @arg1
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside same arg twice function" do
    assert %{
             variable_at(:arg, 1, 17) => [
               variable_at(:arg, 1, 33),
               variable_at(:arg, 1, 23)
             ]
           } =
             Dataflow.analyze(
               """
               defp bar(%{arg: arg}, arg), do: arg
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside function with guard" do
    assert %{
             variable_at(:arg, 1, 10) => [
               variable_at(:arg, 1, 20)
             ]
           } =
             Dataflow.analyze(
               """
               defp bar(arg) when arg > 10 do
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside anonymous function" do
    assert %{
             variable_at(:list, 1, 10) => [
               variable_at(:list, 2, 12)
             ],
             variable_at(:arg1, 1, 16) => [
               variable_at(:arg1, 10, 3),
               {:arg1,
                [
                  trailing_comments: [],
                  leading_comments: [],
                  # bummer
                  end_of_expression: [newlines: 2, line: 4, column: 12],
                  line: 4,
                  column: 8
                ], nil},
               variable_at(:arg1, 3, 6)
             ],
             variable_at(:arg1, 6, 13) => [
               variable_at(:arg1, 7, 7),
               variable_at(:arg1, 6, 24)
             ]
           } =
             Dataflow.analyze(
               """
               defp bar(list, arg1) do
                 Enum.map(list, fn
                   ^arg1 ->
                      arg1

                   %{arg1: arg1} when arg1 > 10 ->
                     arg1
                 end)

                 arg1
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside guard" do
    assert %{
             variable_at(:arg, 1, 16) => [
               variable_at(:arg, 1, 26)
             ]
           } =
             Dataflow.analyze(
               """
               defguard guard(arg) when arg < 10
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables reused by guards" do
    assert %{
             variable_at(:arg, 2, 3) => [
               variable_at(:arg, 10, 17),
               variable_at(:arg, 7, 16),
               variable_at(:arg, 6, 17)
             ]
           } =
             Dataflow.analyze(
               """
               defp bar() do
                 arg = 10

                 1..30
                 |> Enum.map(fn
                   i when i <= arg -> i
                   i when i > arg -> i + 10
                 end)

                with true when arg > 10 <- true do
                end
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables after a reassignment" do
    assert %{
             variable_at(:arg, 1, 9) => [
               variable_at(:arg, 2, 9)
             ],
             variable_at(:arg, 2, 3) => [
               variable_at(:arg, 3, 3)
             ]
           } =
             Dataflow.analyze(
               """
               def bar(arg) do
                 arg = arg + 10
                 arg * 20
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside CASE statement" do
    assert %{
             variable_at(:arg1, 1, 9) => [
               variable_at(:arg1, 11, 10),
               variable_at(:arg1, 2, 15)
             ],
             variable_at(:arg2, 1, 15) => [
               variable_at(:arg2, 11, 3),
               variable_at(:arg2, 2, 22)
             ],
             variable_at(:arg2, 2, 8) => [
               variable_at(:arg2, 4, 14)
             ],
             variable_at(:arg2, 4, 7) => [
               variable_at(:arg2, 5, 7)
             ],
             variable_at(:arg1, 7, 5) => [
               variable_at(:arg1, 8, 7),
               variable_at(:arg1, 7, 15)
             ]
           } =
             Dataflow.analyze(
               """
               def bar(arg1, arg2) do
                 case arg2 = arg1 + arg2 do
                   20 ->
                     arg2 = arg2 + 5
                     arg2 + 40

                   arg1 when arg1 < 1 ->
                     arg1 + 12
                 end

                 arg2 + arg1
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside COND statement" do
    assert %{
             variable_at(:arg, 1, 9) => [
               variable_at(:arg, 10, 3),
               variable_at(:arg, 6, 11),
               variable_at(:arg, 4, 7),
               variable_at(:arg, 3, 5)
             ],
             variable_at(:arg, 6, 5) => [
               variable_at(:arg, 7, 7),
               variable_at(:arg, 6, 25)
             ]
           } =
             Dataflow.analyze(
               """
               def bar(arg) do
                 cond do
                   arg == 15 ->
                     arg * 15

                   arg = arg + 10 when arg > 10 ->
                     arg * 10
                 end

                 arg
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside WITH statement" do
    assert %{
             variable_at(:arg1, 1, 9) => [
               variable_at(:arg1, 13, 3),
               variable_at(:arg1, 9, 10),
               variable_at(:arg1, 3, 16),
               variable_at(:arg1, 2, 16)
             ],
             variable_at(:arg2, 2, 8) => [
               variable_at(:arg2, 4, 23),
               variable_at(:arg2, 3, 25)
             ],
             variable_at(:arg1, 4, 8) => [
               variable_at(:arg1, 6, 19),
               variable_at(:arg1, 5, 31),
               variable_at(:arg1, 4, 15)
             ],
             variable_at(:arg2, 5, 8) => [
               variable_at(:arg2, 6, 12),
               variable_at(:arg2, 5, 18)
             ],
             variable_at(:arg1, 6, 5) => [
               variable_at(:arg1, 7, 5)
             ],
             variable_at(:e, 9, 5) => [
               variable_at(:e, 9, 17)
             ],
             variable_at(:arg1, 10, 5) => [
               variable_at(:arg1, 10, 13)
             ]
           } =
             Dataflow.analyze(
               """
               def bar(arg1) do
                 with arg2 <- arg1,
                      %{arg: ^arg1} <- arg2,
                      arg1 = arg1 <- arg2,
                      arg2 when arg2 < 20 <- arg1 do
                   arg1 = arg2 + arg1
                   arg1 * 10
                 else
                   e -> arg1 + e
                   arg1 -> arg1
                 end

                 arg1
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside TRY statement" do
    assert %{
             variable_at(:arg, 1, 9) => [
               variable_at(:arg, 14, 3),
               variable_at(:arg, 10, 11),
               variable_at(:arg, 8, 14),
               variable_at(:arg, 3, 11)
             ],
             variable_at(:arg, 3, 5) => [
               variable_at(:arg, 4, 5)
             ],
             variable_at(:arg, 6, 5) => [
               variable_at(:arg, 6, 12)
             ],
             variable_at(:e, 8, 5) => [
               variable_at(:e, 8, 10)
             ],
             variable_at(:arg, 10, 5) => [
               variable_at(:arg, 11, 5)
             ]
           } =
             Dataflow.analyze(
               """
               def bar(arg) do
                 try do
                   arg = arg * 15
                   arg + 10
                 rescue
                   arg -> arg
                 catch
                   e -> e + arg
                 after
                   arg = arg + 10
                   arg
                 end

                 arg
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside IF statement" do
    assert %{
             variable_at(:arg, 1, 9) => [
               variable_at(:arg, 10, 3),
               variable_at(:arg, 2, 12)
             ],
             variable_at(:arg, 2, 6) => [
               variable_at(:arg, 6, 11),
               variable_at(:arg, 3, 11)
             ],
             variable_at(:arg, 3, 5) => [
               variable_at(:arg, 4, 5)
             ],
             variable_at(:arg, 6, 5) => [
               variable_at(:arg, 7, 5)
             ]
           } =
             Dataflow.analyze(
               """
               def bar(arg) do
                 if arg = arg + 10 do
                   arg = arg * 15
                   arg + 10
                 else
                   arg = arg * 20
                   arg + 25
                 end

                 arg
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside UNLESS statement" do
    assert %{
             variable_at(:arg, 1, 9) => [
               variable_at(:arg, 10, 3),
               variable_at(:arg, 2, 16)
             ],
             variable_at(:arg, 2, 10) => [
               variable_at(:arg, 6, 11),
               variable_at(:arg, 3, 11)
             ],
             variable_at(:arg, 3, 5) => [
               variable_at(:arg, 4, 5)
             ],
             variable_at(:arg, 6, 5) => [
               variable_at(:arg, 7, 5)
             ]
           } =
             Dataflow.analyze(
               """
               def bar(arg) do
                 unless arg = arg + 10 do
                   arg = arg * 15
                   arg + 10
                 else
                   arg = arg * 20
                   arg + 25
                 end

                 arg
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside FOR statement" do
    assert %{
             variable_at(:arg1, 1, 9) => [
               variable_at(:arg1, 11, 3),
               variable_at(:arg1, 4, 18)
             ],
             variable_at(:arg2, 2, 7) => [
               variable_at(:arg2, 3, 14)
             ],
             variable_at(:arg2, 3, 7) => [
               variable_at(:arg2, 7, 19),
               variable_at(:arg2, 5, 14)
             ],
             variable_at(:arg1, 4, 7) => [
               variable_at(:arg1, 7, 13),
               variable_at(:arg1, 5, 7)
             ],
             variable_at(:arg1, 7, 5) => [
               variable_at(:arg1, 8, 5)
             ]
           } =
             Dataflow.analyze(
               """
               def bar(arg1) do
                 for arg2 <- 1..5,
                     arg2 = arg2 + 10,
                     arg1 <- 0..arg1,
                     arg1 + arg2 < 4,
                     into: %{} do
                   arg1 = {arg1, arg2}
                   arg1
                 end

                 arg1
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside test macro" do
    assert %{
             variable_at(:arg, 2, 3) => [
               variable_at(:arg, 15, 3)
             ],
             variable_at(:arg, 4, 38) => [
               variable_at(:arg, 5, 11)
             ],
             variable_at(:arg, 5, 5) => [
               variable_at(:arg, 6, 5)
             ],
             variable_at(:arg, 11, 5) => [
               variable_at(:arg, 12, 5)
             ]
           } =
             Dataflow.analyze(
               """
               defmodule Test do
                 arg = 10

                 test "test with variables", %{arg: arg} do
                   arg = arg + 10
                   arg
                 end

                 test "test with variables" do
                   arg # ignored
                   arg = arg + 20
                   arg
                 end

                 arg
               end
               """
               |> Sourceror.parse_string!()
             )
  end

  test "lists all variables inside module" do
    assert %{
             variable_at(:arg, 2, 3) => [
               variable_at(:arg, 18, 3),
               variable_at(:arg, 5, 11)
             ],
             variable_at(:arg, 5, 5) => [
               variable_at(:arg, 15, 5)
             ],
             variable_at(:arg, 11, 19) => [
               variable_at(:arg, 12, 7)
             ]
           } =
             Dataflow.analyze(
               """
               defmodule Outer do
                 arg = 10

                 defmodule Mod do
                   arg = arg + 20

                   def function() do
                     arg # ignored
                   end

                   def function2(arg) do
                     arg
                   end

                   arg
                 end

                 arg + 20
               end
               """
               |> Sourceror.parse_string!()
             )
  end
end
