defmodule Refactorex.Refactor.Function do
  alias Sourceror.Zipper, as: Z

  defguard function_id?(id) when id in ~w(def defp)a

  def go_to_function_block(%{node: {id, _, _}} = zipper) when function_id?(id) do
    zipper
    |> Z.down()
    |> Z.right()
    |> Z.down()
  end
end
