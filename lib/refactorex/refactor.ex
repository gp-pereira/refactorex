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

      def available?(_, node)
          when is_number(node) and unquote(works_on) == :selection,
          do: false

      def available?(_, line)
          when not is_number(line) and unquote(works_on) == :line,
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
    __MODULE__.Function.ExtractAnonymousFunction,
    __MODULE__.Function.ExtractFunction,
    __MODULE__.Function.UnderlineUnusedArgs,
    __MODULE__.Function.UseKeywordSyntax,
    __MODULE__.Function.UseRegularSyntax,
    __MODULE__.Pipeline.PipeFirstArg,
    __MODULE__.Pipeline.RemovePipe,
    __MODULE__.Variable.ExtractConstant
  ]

  alias __MODULE__.Selection

  def available_refactorings(original, range, modules \\ @refactors) do
    with {:ok, selection_or_line} <- Selection.selection_or_line(original, range),
         {:ok, macro} <- Sourceror.parse_string(original) do
      zipper = Sourceror.Zipper.zip(macro)

      modules
      |> Stream.map(&{&1, &1.available?(zipper, selection_or_line)})
      |> Stream.filter(&match?({_, true}, &1))
      |> Enum.map(fn {module, _} -> module.refactoring() end)
    else
      # this error means the file could not be parsed,
      # so there are no refactorings available for it
      {:error, _} -> []
    end
  end

  def refactor(original, range, module) do
    {:ok, selection_or_line} = Selection.selection_or_line(original, range)
    module = String.to_atom(module)

    original
    |> Sourceror.parse_string!()
    |> Sourceror.Zipper.zip()
    |> module.execute(selection_or_line)
    |> then(&Refactorex.Diff.find_diffs(original, &1))
    |> module.refactoring()
  end
end
