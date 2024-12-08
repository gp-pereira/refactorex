defmodule Refactorex.Refactor.Guard.RenameGuardTest do
  use Refactorex.RefactorCase

  alias Refactorex.Refactor.Guard.RenameGuard

  test "renames the selected private guard definition and usages" do
    assert_refactored(
      RenameGuard,
      """
      defmodule Foo do
        #         v
        defguardp extracted_guard(arg) when arg.valid? == true
        #                       ^

        def foo(arg) when extracted_guard(arg) do
          arg
        end
      end
      """,
      """
      defmodule Foo do
        defguardp #{placeholder()}(arg) when arg.valid? == true

        def foo(arg) when #{placeholder()}(arg) do
          arg
        end
      end
      """
    )
  end

  test "renames the selected public guard usages and redirect definition" do
    assert_refactored(
      RenameGuard,
      """
      defmodule Foo do
        #        v
        defguard generated?(payment) when payment.status.name == "generated"
        #                 ^

        defguardp supported?(socket) when true

        def update(%{payment: payment} = assigns, socket) when generated?(payment) do
          reply_ok(socket, assigns)
        end
      end
      """,
      """
      defmodule Foo do
        defguardp #{placeholder()}(payment) when payment.status.name == "generated"
        defguard generated?(payment) when #{placeholder()}(payment)

        defguardp supported?(socket) when true

        def update(%{payment: payment} = assigns, socket)
            when #{placeholder()}(payment) do
          reply_ok(socket, assigns)
        end
      end
      """
    )
  end

  test "renames only usages with same name and arity" do
    assert_refactored(
      RenameGuard,
      """
      defmodule Foo do
        #         v
        defguardp my_guard(arg1, arg2) when arg.valid? == true
        #                ^

        defguardp my_guard(arg) when arg == true
        defguardp other_guard(arg1, arg2) when arg1 == true

        def foo(arg) when my_guard(arg, arg) and my_guard(arg) or other_guard(arg, arg) do
          my_guard(arg, arg + 5)
        end

        defp my_guard(a, b) do
          a + b
        end
      end
      """,
      """
      defmodule Foo do
        defguardp #{placeholder()}(arg1, arg2) when arg.valid? == true

        defguardp my_guard(arg) when arg == true
        defguardp other_guard(arg1, arg2) when arg1 == true

        def foo(arg)
            when (#{placeholder()}(arg, arg) and my_guard(arg)) or other_guard(arg, arg) do
          my_guard(arg, arg + 5)
        end

        defp my_guard(a, b) do
          a + b
        end
      end
      """
    )
  end

  test "renames by selecting the usage instead of the definition" do
    assert_refactored(
      RenameGuard,
      """
      defmodule Foo do
        defguardp extracted_guard(arg) when arg.valid? == true

        #                 v
        def foo(arg) when extracted_guard(arg) do
        #                               ^
          arg
        end
      end
      """,
      """
      defmodule Foo do
        defguardp #{placeholder()}(arg) when arg.valid? == true

        def foo(arg) when #{placeholder()}(arg) do
          arg
        end
      end
      """
    )
  end

  test "renames only affects the current file" do
    assert_refactored(
      RenameGuard,
      """
      defmodule Before do
        defguardp some_guard(arg) when arg.valid? == true

        def foo(arg) when some_guard(arg) do
          arg
        end
      end

      defmodule Foo do
        defguardp some_guard(arg) when arg.valid? == true

        #                 v
        def foo(arg) when some_guard(arg) do
        #                          ^
          arg
        end
      end

      defmodule After do
        defguardp some_guard(arg) when arg.valid? == true

        def foo(arg) when some_guard(arg) do
          arg
        end
      end
      """,
      """
      defmodule Before do
        defguardp some_guard(arg) when arg.valid? == true

        def foo(arg) when some_guard(arg) do
          arg
        end
      end

      defmodule Foo do
        defguardp #{placeholder()}(arg) when arg.valid? == true

        def foo(arg) when #{placeholder()}(arg) do
          arg
        end
      end

      defmodule After do
        defguardp some_guard(arg) when arg.valid? == true

        def foo(arg) when some_guard(arg) do
          arg
        end
      end
      """
    )
  end

  test "ignores selection outside module" do
    assert_not_refactored(
      RenameGuard,
      """
      #         v
      defguardp extracted_guard(arg) when arg.valid? == true
      #                       ^

      def foo(arg) when extracted_guard(arg) do
        arg
      end
      """
    )
  end
end
