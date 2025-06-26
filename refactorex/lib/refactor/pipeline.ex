defmodule Refactorex.Refactor.Pipeline do
  @moduledoc """
  └──:|>           <- top
     ├──:|>
     │  ├──:|>
     │  │  ├──:arg <- start
     │  │  └──:foo
     │  └──:bar
     └──:qez       <- end
  """

  alias Sourceror.Zipper, as: Z
  alias Refactorex.Refactor.AST

  def starts_at?({:|>, _, [{:|>, _, _} = start, _]}, macro),
    do: starts_at?(start, macro)

  def starts_at?({:|>, _, [start, _]}, macro),
    do: AST.equal?(start, macro)

  def starts_at?(_, _), do: false

  def update_start(pipeline, updater) do
    pipeline
    |> Z.zip()
    |> Z.find(&starts_at?(pipeline, &1))
    |> Z.update(updater)
    |> Z.top()
    |> Z.node()
  end

  def go_to_top(zipper, {:|>, _, [_, end_]} = pipeline) do
    %{node: {:|>, _, [_, node]}} = up = Z.up(zipper)

    if AST.equal?(node, end_),
      do: up,
      else: go_to_top(up, pipeline)
  end
end
