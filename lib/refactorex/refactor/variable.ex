defmodule Refactorex.Refactor.Variable do
  alias Sourceror.Zipper, as: Z

  import Sourceror.Identifier

  @not_variable ~w(binary)a

  def find_variables(node, opts \\ []) do
    reject = opts[:reject] || fn _ -> false end
    unique = if is_nil(opts[:unique]), do: true, else: opts[:unique]

    node
    |> Z.zip()
    |> Z.traverse_while([], fn
      %{node: {id, _, nil} = variable} = zipper, variables when is_identifier(variable) ->
        cond do
          Enum.member?(@not_variable, id) ->
            {:cont, zipper, variables}

          match?(%{node: {:@, _, _}}, Z.up(zipper)) ->
            {:cont, zipper, variables}

          reject.(zipper) ->
            {:cont, zipper, variables}

          true ->
            {:cont, zipper, variables ++ [variable]}
        end

      zipper, variables ->
        {:cont, zipper, variables}
    end)
    |> elem(1)
    |> then(&if unique, do: remove_duplicates(&1), else: &1)
  end

  def remove_duplicates(variables),
    do: Enum.uniq_by(variables, fn {id, _, _} -> id end)

  def member?(variables, {variable_id, _, _} = _variable),
    do: Enum.any?(variables, fn {id, _, _} -> id == variable_id end)

  def member?(_, _), do: false
end
