defmodule Refactorex.Refactor do
  alias Sourceror.Zipper

  @type selection_or_line :: Macro.t() | pos_integer()

  @callback can_refactor?(Zipper.t(), selection_or_line) :: :skip | true | false
  @callback refactor(Zipper.t(), selection_or_line) :: Zipper.t()

  defmacro __using__(attrs) do
    works_on = Keyword.fetch!(attrs, :works_on)

    quote do
      alias Sourceror.Zipper, as: Z
      alias Refactorex.Refactor.AST

      @behaviour Refactorex.Refactor

      @dialyzer {:no_match, available?: 2, visit: 4}

      defguardp line?(selection_or_line) when is_number(selection_or_line)

      def available?(_, selection_or_line)
          when line?(selection_or_line) and unquote(works_on != :line),
          do: false

      def available?(_, selection_or_line)
          when not line?(selection_or_line) and unquote(works_on != :selection),
          do: false

      def available?(zipper, selection_or_line) do
        zipper
        |> Z.traverse_while(false, &visit(&1, &2, selection_or_line, false))
        |> then(fn {_, available?} -> available? end)
      end

      def execute(zipper, selection_or_line) do
        zipper
        |> Z.traverse_while(false, &visit(&1, &2, selection_or_line, true))
        |> then(fn {%{node: node}, true} -> Sourceror.to_string(node) end)
      end

      defp visit(zipper, false, selection_or_line, refactor?) do
        case can_refactor?(zipper, selection_or_line) do
          :skip ->
            {:skip, zipper, false}

          false ->
            {:cont, zipper, false}

          true ->
            {
              :halt,
              if(refactor?, do: refactor(zipper, selection_or_line), else: zipper),
              true
            }
        end
      end

      def refactoring(refactored \\ nil) do
        %Refactorex.Refactoring{
          module: __MODULE__,
          title: unquote(Keyword.fetch!(attrs, :title)),
          kind: unquote(Keyword.fetch!(attrs, :kind)),
          refactored: refactored
        }
      end
    end
  end

  @refactors [
    __MODULE__.Function.ExpandAnonymousFunction,
    __MODULE__.Function.ExtractAnonymousFunction,
    __MODULE__.Function.ExtractFunction,
    __MODULE__.Function.UnderscoreUnusedArgs,
    __MODULE__.Function.UseKeywordSyntax,
    __MODULE__.Function.UseRegularSyntax,
    __MODULE__.Pipeline.PipeFirstArg,
    __MODULE__.Pipeline.RemovePipe,
    __MODULE__.Variable.ExtractConstant
  ]

  def available_refactorings(zipper, selection_or_line) do
    @refactors
    |> Stream.map(&{&1, &1.available?(zipper, selection_or_line)})
    |> Stream.filter(&match?({_, true}, &1))
    |> Enum.map(fn {module, _} -> module.refactoring() end)
  end

  def refactor(zipper, selection_or_line, module) do
    module = String.to_atom(module)

    zipper
    |> module.execute(selection_or_line)
    |> module.refactoring()
  end
end
