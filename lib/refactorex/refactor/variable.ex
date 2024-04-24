defmodule Refactorex.Refactor.Variable do
  alias Sourceror.Zipper, as: Z

  import Sourceror.Identifier

  @not_variable ~w(binary)a

  def find_used_variables(node, opts \\ []) do
    ignore_ids = Enum.map(opts[:ignore] || [], fn {id, _, _} -> id end)

    node
    |> Z.zip()
    |> Z.traverse_while([], fn
      %{node: {id, _, _} = variable} = zipper, variables when is_identifier(variable) ->
        if Enum.member?(ignore_ids ++ @not_variable, id),
          do: {:cont, zipper, variables},
          else: {:cont, zipper, variables ++ [variable]}

      zipper, variables ->
        {:cont, zipper, variables}
    end)
    |> elem(1)
    |> Enum.uniq_by(fn {id, _, _} -> id end)
  end
end
