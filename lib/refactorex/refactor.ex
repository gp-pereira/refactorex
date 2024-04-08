defmodule Refactorex.Refactor do
  alias Sourceror.Zipper

  @callback can_refactor?(Zipper.t(), term()) :: :skip | true | false
  @callback refactor(Zipper.t()) :: Zipper.t()

  defmacro __using__(attrs) do
    quote do
      alias Sourceror.Zipper, as: Z

      @behaviour Refactorex.Refactor

      def refactor(text, t, opts \\ []) do
        case Sourceror.parse_string(text) do
          {:ok, macro} ->
            macro
            |> Z.zip()
            |> Z.traverse_while(false, &maybe_refactor(&1, &2, t))
            |> then(fn {zipper, refactored?} ->
              if opts[:raw],
                do: {zipper.node, refactored?},
                else: {Sourceror.to_string(zipper.node), refactored?}
            end)
        end
      end

      @docs """
      Disabled because some Refactors don't return all three types
      """
      @dialyzer {:no_match, maybe_refactor: 3}

      defp maybe_refactor(zipper, false, t) do
        case can_refactor?(zipper, t) do
          :skip ->
            {:skip, zipper, false}

          true ->
            {:halt, refactor(zipper), true}

          false ->
            {:cont, zipper, false}
        end
      end

      def identify_refactor(text) do
        %{
          text: text,
          title: unquote(Keyword.fetch!(attrs, :title)),
          kind: unquote(Keyword.fetch!(attrs, :kind))
        }
      end
    end
  end
end
