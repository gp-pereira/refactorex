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

      defdelegate placeholder, to: Refactorex.Refactor
    end
  end

  @refactors [
    __MODULE__.Alias.ExpandAliases,
    __MODULE__.Alias.ExtractAlias,
    __MODULE__.Alias.InlineAlias,
    __MODULE__.Alias.MergeAliases,
    __MODULE__.Alias.SortNestedAliases,
    __MODULE__.Constant.ExtractConstant,
    __MODULE__.Constant.InlineConstant,
    __MODULE__.Function.CollapseAnonymousFunction,
    __MODULE__.Function.ExpandAnonymousFunction,
    __MODULE__.Function.ExtractAnonymousFunction,
    __MODULE__.Function.ExtractFunction,
    __MODULE__.Function.InlineFunction,
    __MODULE__.Function.UseKeywordSyntax,
    __MODULE__.Function.UseRegularSyntax,
    __MODULE__.Guard.ExtractGuard,
    __MODULE__.Guard.InlineGuard,
    __MODULE__.IfElse.UseKeywordSyntax,
    __MODULE__.IfElse.UseRegularSyntax,
    __MODULE__.Pipeline.IntroduceIOInspect,
    __MODULE__.Pipeline.IntroducePipe,
    __MODULE__.Pipeline.RemoveIOInspect,
    __MODULE__.Pipeline.RemovePipe,
    __MODULE__.Variable.ExtractVariable,
    __MODULE__.Variable.InlineVariable,
    __MODULE__.Variable.UnderscoreNotUsed
  ]

  @renamers [
    __MODULE__.Constant.RenameConstant,
    __MODULE__.Function.RenameFunction,
    __MODULE__.Guard.RenameGuard,
    __MODULE__.Variable.RenameVariable
  ]

  def available_refactorings(zipper, selection_or_line, modules \\ @refactors) do
    __MODULE__
    |> Task.Supervisor.async_stream_nolink(modules, fn module ->
      if module.available?(zipper, selection_or_line),
        do: module.refactoring(),
        else: nil
    end)
    |> Enum.reduce([], fn
      {:ok, nil}, refactorings ->
        refactorings

      {:ok, refactoring}, refactorings ->
        [refactoring | refactorings]

      {:exit, _reason}, refactorings ->
        refactorings
    end)
  end

  def refactor(zipper, selection_or_line, module) do
    module = String.to_atom(module)

    zipper
    |> module.execute(selection_or_line)
    |> module.refactoring()
  end

  def rename_available?(zipper, selection),
    do: length(available_refactorings(zipper, selection, @renamers)) == 1

  def rename(zipper, selection, new_name) do
    [%{module: module}] = available_refactorings(zipper, selection, @renamers)

    zipper
    |> module.execute(selection)
    |> String.replace("#{placeholder()}", new_name)
    |> module.refactoring()
  end

  def placeholder(), do: :__y__
end
