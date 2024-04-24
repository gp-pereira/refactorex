defmodule Refactorex.Refactor.Function.ExtractAnonymousFunctionTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Function.ExtractAnonymousFunction

  test "extracts anonymous function to a private function" do
    assert_refactored(
      ExtractAnonymousFunction,
      """
      defmodule Foo do
        def read_files do
          filenames
          #           v
          |> Enum.map(fn filename -> File.read!(filename) end)
          #                                                 ^
          |> Enum.join("")
        end
      end
      """,
      """
      defmodule Foo do
        def read_files do
          filenames
          |> Enum.map(&extracted_function(&1))
          |> Enum.join("")
        end

        defp extracted_function(filename) do
          File.read!(filename)
        end
      end
      """
    )
  end

  test "extracts anonymous function always put it on the end of module" do
    assert_refactored(
      ExtractAnonymousFunction,
      """
      defmodule Foo do
        def read_files do
          filenames
          #           v
          |> Enum.map(fn filename -> File.read!(filename) end)
          #                                                 ^
          |> Enum.join("")
        end

        def foo(arg), do: arg
      end
      """,
      """
      defmodule Foo do
        def read_files do
          filenames
          |> Enum.map(&extracted_function(&1))
          |> Enum.join("")
        end

        def foo(arg), do: arg

        defp extracted_function(filename) do
          File.read!(filename)
        end
      end
      """
    )
  end

  test "extracts anonymous function with N arguments" do
    assert_refactored(
      ExtractAnonymousFunction,
      """
      defmodule Foo do
        def sum(numbers) do
          #                       v
          Enum.reduce(numbers, 0, fn i, acc -> i + acc end)
          #                                              ^
        end
      end
      """,
      """
      defmodule Foo do
        def sum(numbers) do
          Enum.reduce(numbers, 0, &extracted_function(&1, &2))
        end

        defp extracted_function(i, acc) do
          i + acc
        end
      end
      """
    )
  end

  test "extracts anonymous function with simplified syntax" do
    assert_refactored(
      ExtractAnonymousFunction,
      """
      defmodule Foo do
        def power_sum(numbers, power) do
          #                       v
          Enum.reduce(numbers, 0, & pow(&1, power) + &2)
          #                                           ^
        end
      end
      """,
      """
      defmodule Foo do
        def power_sum(numbers, power) do
          Enum.reduce(numbers, 0, &extracted_function(&1, &2, power))
        end

        defp extracted_function(arg1, arg2, power) do
          pow(arg1, power) + arg2
        end
      end
      """
    )
  end

  test "extracts anonymous function that uses outer scope variables" do
    assert_refactored(
      ExtractAnonymousFunction,
      """
      defmodule Foo do
        def files(folders) do
          file = "foo"
          ext = "ex"

          folders
          #           v
          |> Enum.map(fn folder -> "\#{folder}/\#{file}_\#{file}.\#{ext}" end)
          #                         \          \        \        \          ^
        end
      end
      """,
      """
      defmodule Foo do
        def files(folders) do
          file = "foo"
          ext = "ex"

          folders
          |> Enum.map(&extracted_function(&1, file, ext))
        end

        defp extracted_function(folder, file, ext) do
          "\#{folder}/\#{file}_\#{file}.\#{ext}"
        end
      end
      """
    )
  end

  test "ignores anonymous function that is not inside a module" do
    assert_not_refactored(
      ExtractAnonymousFunction,
      """
      def power_sum(numbers, power) do
        #                       v
        Enum.reduce(numbers, 0, & pow(&1, power) + &2)
        #                                           ^
      end
      """
    )
  end
end
