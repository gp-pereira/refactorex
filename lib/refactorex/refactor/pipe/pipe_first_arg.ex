defmodule Refactorex.Refactor.Pipe.PipeFirstArg do
  use Refactorex.Refactor,
    title: "Pipe first argument into function",
    kind: "refactor.rewrite"

  import Sourceror.Identifier
  require Logger

  def can_refactor?(%{node: {_, _, []}}, _), do: false

  def can_refactor?(%{node: {id, _, _}}, _)
      when id in [:%{}, :__block__, :fn],
      do: false

  def can_refactor?(%{node: {_, _, _} = node} = zipper, range) do
    cond do
      not SelectionRange.starts_on_node_line?(range, node) ->
        false

      not can_pipe_into?(node) ->
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

  defp can_pipe_into?({{:., _, [Access | _]}, _, _}), do: false
  defp can_pipe_into?({:., _, [Access | _]}), do: false
  defp can_pipe_into?({:case, _, _}), do: true

  defp can_pipe_into?({_, meta, _} = node),
    do: !!meta[:closing] and is_call(node)
end
