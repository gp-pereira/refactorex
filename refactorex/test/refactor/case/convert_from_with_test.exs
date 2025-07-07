defmodule Refactorex.Refactor.Case.ConvertFromWithTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Case.ConvertFromWith

  test "converts a simple with into a case" do
    assert_refactored(
      ConvertFromWith,
      """
      def foo() do
        #          v
        with {:ok, result} <- Foo.bar() do
          {:ok, result + 16}
        end
      end
      """,
      """
      def foo() do
        case Foo.bar() do
          {:ok, result} -> {:ok, result + 16}
          other -> other
        end
      end
      """
    )
  end

  test "converts a with plus else clauses into a case" do
    assert_refactored(
      ConvertFromWith,
      """
      #          v
      with {:ok, %{result: 16}} <- Foo.bar() do
        {:ok, 16 + 16}
      else
        {:ok, result} ->
          {:ok, result + 32}

        {:error, reason} ->
          {:error, reason}
      end
      """,
      """
      case Foo.bar() do
        {:ok, %{result: 16}} ->
          {:ok, 16 + 16}

        {:ok, result} ->
          {:ok, result + 32}

        {:error, reason} ->
          {:error, reason}
      end
      """
    )
  end

  test "converts a case using when clause into a with" do
    assert_refactored(
      ConvertFromWith,
      """
      #          v
      with {:ok, result} when is_integer(result) <- Foo.bar() do
        {:ok, result + 16}
      else
        {:ok, result} when is_float(result) ->
          {:ok, result + 32}
      end
      """,
      """
      case Foo.bar() do
        {:ok, result} when is_integer(result) ->
          {:ok, result + 16}

        {:ok, result} when is_float(result) ->
          {:ok, result + 32}
      end
      """
    )
  end

  test "converts a with without a block into a case" do
    assert_refactored(
      ConvertFromWith,
      """
      #          v
      with {:ok, result} <- Foo.bar() do
      end
      """,
      """
      case Foo.bar() do
        {:ok, result} -> nil
        other -> other
      end
      """
    )
  end

  test "ignores a multi match with" do
    assert_ignored(
      ConvertFromWith,
      """
      #          v
      with {:ok, result} <- Foo.bar(),
           {:ok, other} <- Foo.other(result) do
        {:ok, result + other}
      end
      """
    )
  end
end
