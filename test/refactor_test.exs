defmodule Refactorex.RefactorTest do
  use ExUnit.Case

  alias Refactorex.Refactor
  alias Refactorex.Refactoring
  alias Refactor.Function.KeywordSyntax

  test "returns refactoring that can be performed on some text and range" do
    same_refactor_twice = [KeywordSyntax, KeywordSyntax]

    assert Refactor.available_refactorings(
             """
             defmodule Foo do
              def bar do
              end
             end
             """,
             %{
               start: %{line: 2, character: 0},
               end: %{line: 2, character: 4}
             },
             same_refactor_twice
           ) == [
             %Refactoring{
               title: "Rewrite function using keyword syntax",
               kind: "refactor.rewrite",
               diffs: [
                 %{
                   text: "  def bar, do: nil",
                   range: %{
                     start: %{character: 0, line: 2},
                     end: %{character: 4, line: 2}
                   }
                 }
               ]
             },
             %Refactoring{
               title: "Rewrite function using keyword syntax",
               kind: "refactor.rewrite",
               diffs: [
                 %{
                   text: "  def bar, do: nil",
                   range: %{
                     start: %{character: 0, line: 2},
                     end: %{character: 4, line: 2}
                   }
                 }
               ]
             }
           ]
  end
end

# comeca em 1
