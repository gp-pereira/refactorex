defmodule Refactorex.Refactor.Guard do
  alias Sourceror.Zipper, as: Z

  def guard_statement?(zipper) do
    case parent = Z.up(zipper) do
      %{node: {:when, _, _}} ->
        true

      %{node: {id, _, _}} when id in ~w(and or not)a ->
        guard_statement?(parent)

      _ ->
        false
    end
  end
end
