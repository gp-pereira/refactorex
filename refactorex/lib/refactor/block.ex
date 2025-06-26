defmodule Refactorex.Refactor.Block do
  def has_multiple_statements?(block)

  def has_multiple_statements?({{:__block__, _, _}, {:__block__, _, _} = block}),
    do: has_multiple_statements?(block)

  def has_multiple_statements?({:__block__, _, [_]}), do: false
  def has_multiple_statements?({:__block__, _, [_ | _]}), do: true
  def has_multiple_statements?(_), do: false
end
