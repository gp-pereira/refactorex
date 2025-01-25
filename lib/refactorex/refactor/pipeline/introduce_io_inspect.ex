defmodule Refactorex.Refactor.Pipeline.IntroduceIOInspect do
  use Refactorex.Refactor,
    title: "Introduce IO.inspect",
    kind: "quickfix",
    works_on: :selection

  alias Refactorex.Refactor.Variable

  @io_inspect_call {{:., [], [{:__aliases__, [], [:IO]}, :inspect]}, [], []}

  def can_refactor?(_, {:&, _, [body]})
      when not is_number(body),
      do: false

  def can_refactor?(_, {id, _, _})
      when id in ~w(<- alias __aliases__)a,
      do: :skip

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      Variable.inside_declaration?(zipper) ->
        false

      invalid_parent?(zipper) ->
        false

      true ->
        true
    end
  end

  def refactor(%{node: node} = zipper, _),
    do: Z.replace(zipper, {:|>, [], [node, @io_inspect_call]})

  defp invalid_parent?(%{node: node} = zipper) do
    case Z.up(zipper) do
      %{node: {:|>, _, [_, ^node]}} -> true
      %{node: {:@, _, [^node]}} -> true
      _ -> false
    end
  end
end
