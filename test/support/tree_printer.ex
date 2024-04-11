defmodule Refactorex.TreePrinter do
  alias Sourceror.Zipper, as: Z

  @elbow "└──"
  @pipe "│  "
  @tee "├──"
  @blank "   "

  def print(any, last? \\ true, header \\ "")

  def print(%Z{node: {{:., _, _}, meta, _} = node}, last?, header) do
    print_node(":.", last?, header, meta)
    loop_children(node, "#{header}#{blank_or_pipe(last?)}")
  end

  def print(%Z{node: {id, meta, maybe_children} = node}, last?, header) do
    print_node(id, last?, header, meta)

    if maybe_children,
      do: loop_children(node, "#{header}#{blank_or_pipe(last?)}")
  end

  def print(%Z{node: node}, _last?, header)
      when is_tuple(node) or is_list(node),
      do: loop_children(node, header)

  def print(%Z{node: node}, last?, header),
    do: print_node(node, last?, header)

  def print(not_zipper, last?, header),
    do: print(Z.zip(not_zipper), last?, header)

  defp loop_children(node, header) do
    children = Z.children(node)

    children
    |> Enum.with_index()
    |> Enum.map(fn {child, i} ->
      print(child, i == length(children) - 1, header)
    end)
  end

  defp print_node(node, last?, header, meta \\ []) do
    meta = Keyword.drop(meta, [:trailing_comments, :leading_comments])
    IO.puts("#{header}#{elbow_or_tee(last?)}#{inspect(node)} #{inspect(meta)}")
  end

  defp elbow_or_tee(last?), do: if(last?, do: @elbow, else: @tee)
  defp blank_or_pipe(last?), do: if(last?, do: @blank, else: @pipe)
end
