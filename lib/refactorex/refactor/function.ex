defmodule Refactorex.Refactor.Function do
  alias Sourceror.Zipper, as: Z

  import Refactorex.Refactor.Range

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

  defp function_call?(aliases, meta, range) do
    # this is the most important tag to
    # determine if the node is a function
    if is_nil(meta[:closing]) do
      false
    else
      # Knowing that the node is indeed a function,
      # move its start column to before its aliases
      # and check if the range is inside of it
      aliases_length =
        aliases
        |> Enum.map(&Atom.to_string/1)
        |> Enum.join(".")
        |> String.length()

      meta = Keyword.update!(meta, :column, &(&1 - aliases_length))

      range_inside_of?(range, meta, meta[:closing])
    end
  end
end
