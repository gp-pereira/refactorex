defmodule Refactorex.Refactor.Function do
  alias Sourceror.Zipper, as: Z

  defguard function_id?(id) when id in ~w(def defp)a

  def go_to_function_block(%{node: {id, _, _}} = zipper) when function_id?(id) do
    zipper
    |> Z.down()
    |> Z.right()
    |> Z.down()
  end

  def function_call?(node, range)

  def function_call?({:., _, [Access | _]}, _), do: false

  def function_call?({{:., _, [{id, _, nil}, _]}, meta, _}, range),
    do: function_call?([id], meta, range)

  def function_call?({{:., _, [{_, _, aliases}, _]}, meta, _}, range),
    do: function_call?(aliases, meta, range)

  def function_call?({id, meta, _}, range) when is_atom(id),
    do: function_call?([id], meta, range)

  def function_call?(_, _), do: false

  defp function_call?(ids, meta, range) do
    if is_nil(meta[:closing]) do
      false
    else
      %{start: %{character: s}} = range

      id_length =
        ids
        |> Enum.map(&Atom.to_string/1)
        |> Enum.join(".")
        |> String.length()

      s >= meta[:column] - id_length and s <= meta[:closing][:column]
    end
  end
end
