defmodule Refactorex.Refactor.AST do
  alias Sourceror.Zipper, as: Z

  @confusing_meta_tags ~w(
    end_of_expression
    leading_comments
    trailing_comments
  )a

  def equal?(macro, macro), do: true

  def equal?({id, _, _} = macro1, {id, _, _} = macro2),
    do: simpler_meta(macro1) == simpler_meta(macro2)

  def equal?(_, _), do: false

  defp simpler_meta(node) do
    node
    |> Z.zip()
    |> Z.traverse(fn
      %{node: {id, meta, block}} = zipper ->
        Z.replace(zipper, {id, Keyword.drop(meta, @confusing_meta_tags), block})

      zipper ->
        zipper
    end)
    |> Z.node()
  end
end
