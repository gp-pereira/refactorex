defmodule Refactorex.Refactor.Case.ConvertToWithTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Case.ConvertToWith

  test "converts a simple case into a with" do
    assert_refactored(
      ConvertToWith,
      """
      def foo() do
        #          v
        case Foo.bar() do
          {:ok, result} ->
            {:ok, result + 16}
        end
      end
      """,
      """
      def foo() do
        with {:ok, result} <- Foo.bar() do
          {:ok, result + 16}
        end
      end
      """
    )
  end

  test "converts a multi clause case into a with" do
    assert_refactored(
      ConvertToWith,
      """
      #          v
      case Foo.bar() do
        {:ok, %{result: 16}} ->
          {:ok, 16 + 16}

        {:ok, result} ->
          {:ok, result + 32}

        {:error, reason} ->
          {:error, reason}
      end
      """,
      """
      with {:ok, %{result: 16}} <- Foo.bar() do
        {:ok, 16 + 16}
      else
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
      ConvertToWith,
      """
      #          v
      case Foo.bar() do
        {:ok, result} when is_integer(result) ->
          {:ok, result + 16}

        {:ok, result} when is_float(result) ->
          {:ok, result + 32}
      end
      """,
      """
      with {:ok, result} when is_integer(result) <- Foo.bar() do
        {:ok, result + 16}
      else
        {:ok, result} when is_float(result) ->
          {:ok, result + 32}
      end
      """
    )
  end

  test "converts a case with catch-all clause into a with" do
    assert_refactored(
      ConvertToWith,
      """
      #          v
      case Foo.bar() do
        {:ok, result} ->
          {:ok, result + 16}

        _ ->
          {:error, :unknown}
      end
      """,
      """
      with {:ok, result} <- Foo.bar() do
        {:ok, result + 16}
      else
        _ ->
          {:error, :unknown}
      end
      """
    )
  end

  test "ignores a case without clauses" do
    assert_ignored(
      ConvertToWith,
      """
      #          v
      case Foo.bar() do
      end
      """
    )
  end

  test "ignores a case with an assignment in the expression" do
    assert_ignored(
      ConvertToWith,
      """
      #          v
      case bar = Foo.bar() do
        {:ok, result} ->
          bar

        {:error, reason} ->
          {:ok, bar}
      end
      """
    )
  end

  test "ignores a case after a pipe" do
    assert_ignored(
      ConvertToWith,
      """
      Foo.bar()
      #    v
      |> case do
        {:ok, result} ->
          {:ok, result + 16}

        {:error, reason} ->
          {:error, reason}
      end
      """
    )
  end
end
