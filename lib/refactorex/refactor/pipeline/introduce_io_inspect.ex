defmodule Refactorex.Refactor.Pipeline.IntroduceIOInspect do
  use Refactorex.Refactor,
    title: "Introduce IO.inspect",
    kind: "quickfix",
    works_on: :selection

  alias Refactorex.Refactor.Variable

  def can_refactor?(_, {id, _, _})
      when id in ~w(<- & alias __aliases__)a,
      do: :skip

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      Variable.inside_declaration?(zipper) ->
        false

      true ->
        true
    end
  end

  def refactor(%{node: node} = zipper, _) do
    Z.replace(
      zipper,
      {:|>, [],
       [
         node,
         {{:., [], [{:__aliases__, [], [:IO]}, :inspect]}, [], []}
       ]}
    )
  end
end
