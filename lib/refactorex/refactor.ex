defmodule Refactorex.Refactor do
  alias Sourceror.Zipper

  @callback can_refactor?(Zipper.t(), term()) :: :skip | true | false
  @callback refactor(Zipper.t()) :: Zipper.t()

  defmacro __using__(attrs) do
    quote do
      alias Sourceror.Zipper, as: Z

      @behaviour Refactorex.Refactor

      def available?(zipper, range) do
        zipper
        |> Z.traverse_while(false, &visit(&1, &2, range, false))
        |> then(fn {_, available?} -> available? end)
      end

      def refactor(zipper, range) do
        zipper
        |> Z.traverse_while(false, &visit(&1, &2, range, true))
        |> then(fn {%{node: node}, true} -> Sourceror.to_string(node) end)
      end

      @docs """
      Disabled because some Refactors don't return all three atoms
      """
      @dialyzer {:no_match, visit: 4}

      defp visit(zipper, false, range, refactor?) do
        case can_refactor?(zipper, range) do
          :skip ->
            {:skip, zipper, false}

          false ->
            {:cont, zipper, false}

          true ->
            {:halt, if(refactor?, do: refactor(zipper), else: zipper), true}
        end
      end

      def refactoring(diffs \\ []) do
        %Refactorex.Refactoring{
          module: __MODULE__,
          title: unquote(Keyword.fetch!(attrs, :title)),
          kind: unquote(Keyword.fetch!(attrs, :kind)),
          diffs: diffs
        }
      end
    end
  end

  @refactors [
    __MODULE__.Function.KeywordSyntax,
    __MODULE__.Function.RegularSyntax
  ]

  def available_refactorings(original, range, modules \\ @refactors) do
    case Sourceror.parse_string(original)  do
      {:ok, macro} ->
        zipper = Sourceror.Zipper.zip(macro)

        modules
        |> Stream.map(&{&1, &1.available?(zipper, range)})
        |> Stream.filter(&match?({_, true}, &1))
        |> Enum.map(fn {module, _} -> module.refactoring() end)

      # this error means the file could not be parsed,
      # so there are no refactorings available for it
      {:error, _} ->
        []
    end
  end

  def refactor(original, range, module) do
    module = String.to_atom(module)

    original
    |> Sourceror.parse_string!()
    |> Sourceror.Zipper.zip()
    |> module.refactor(range)
    |> then(&Refactorex.Diff.find_diffs(original, &1))
    |> module.refactoring()
  end
end
