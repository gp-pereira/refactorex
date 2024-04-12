defmodule Refactorex.Refactor.Pipe.PipeFirstArgument do
  use Refactorex.Refactor,
    title: "Pipe first argument into function",
    kind: "refactor.rewrite"

  import Refactorex.Refactor.Function

  def can_refactor?(%{node: {_, _, []}}, _), do: false

  def can_refactor?(%{node: {id, _, _}}, _)
      when id in [:%{}, :__block__, :fn],
      do: false

  def can_refactor?(%{node: {_, meta, _}} = zipper, range) do
    %{start: %{line: line}} = range

    cond do
      line < meta[:line] or line > meta[:line] ->
        false

      not can_pipe_into?(zipper.node, range) ->
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

  defp can_pipe_into?({:case, _, _}, _), do: true
  defp can_pipe_into?(node, range), do: function_call?(node, range)
end
