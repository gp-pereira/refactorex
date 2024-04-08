defmodule Refactorex.Refactor do
  alias Sourceror.Zipper

  @type refactored? :: boolean()

  @callback do_refactor(Zipper.t(), refactored?, term()) ::
              {
                :cont | :halt | :skip,
                Zipper.t(),
                refactored?
              }

  defmacro __using__(_) do
    quote do
      alias Sourceror.Zipper, as: Z

      @behaviour Refactorex.Refactor

      def refactor(code, t, opts \\ []) do
        case Sourceror.parse_string(code) do
          {:ok, macro} ->
            macro
            |> Z.zip()
            |> Z.traverse_while(false, &do_refactor(&1, &2, t))
            |> then(fn {zipper, refactored?} ->
              if opts[:raw],
                do: {zipper.node, refactored?},
                else: {Sourceror.to_string(zipper.node), refactored?}
            end)
        end
      end
    end
  end
end
