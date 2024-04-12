defmodule Refactorex.Refactor.Function.PipeFirstArgument do
  use Refactorex.Refactor,
    title: "Pipe first argument into function",
    kind: "refactor.rewrite"

  def can_refactor?(%{node: {_, _, []}}, _), do: false

  def can_refactor?(%{node: {id, _, _}}, _)
      when id in [:%{}, :__block__, :fn],
      do: false

  def can_refactor?(%{node: {_, meta, _}} = zipper, range) do
    %{start: %{line: line}} = range

    cond do
      is_nil(meta[:closing]) ->
        false

      line < meta[:line] or line > meta[:line] ->
        false

      outside_function_call?(zipper, range) ->
        false

      invalid_parent?(zipper) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(zipper) do
    zipper
    |> Z.update(fn {id, meta, [arg | rest]} ->
      {:|>, [], [arg, {id, meta, rest}]}
    end)
  end

  defp invalid_parent?(%{node: {function_id, _, _}} = zipper) do
    zipper
    |> Z.up()
    |> then(fn
      # function is already receiving first argument from a pipe
      %{node: {:|>, _, [_, {^function_id, _, _}]}} ->
        true

      # parent is part of function declaration
      %{node: {parent_id, _, _}} when parent_id in [:def, :defp, :when] ->
        true

      _ ->
        false
    end)
  end

  defp outside_function_call?(%{node: {:., _, [Access | _]}}, _), do: true

  defp outside_function_call?(%{node: {id, meta, _}}, range) when is_atom(id),
    do: outside_function_call?([id], meta, range)

  defp outside_function_call?(%{node: {{:., _, [{id, _, nil}, _]}, meta, _}}, range),
    do: outside_function_call?([id], meta, range)

  defp outside_function_call?(%{node: {{:., _, [{_, _, aliases}, _]}, meta, _}}, range),
    do: outside_function_call?(aliases, meta, range)

  defp outside_function_call?(_, _), do: true

  defp outside_function_call?(ids, meta, %{start: %{character: c}}) do
    id_length =
      ids
      |> Enum.map(&Atom.to_string/1)
      |> Enum.join(".")
      |> String.length()

    c < meta[:column] - id_length or c > meta[:closing][:column]
  end
end
