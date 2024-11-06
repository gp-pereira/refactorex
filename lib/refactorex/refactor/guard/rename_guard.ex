defmodule Refactorex.Refactor.Guard.RenameGuard do
  use Refactorex.Refactor,
    title: "Rename guard",
    kind: "source",
    works_on: :selection

  alias Refactorex.Refactor.{
    Guard,
    Module
  }

  def can_refactor?(%{node: {name, meta, [_ | _]}} = zipper, selection) do
    cond do
      not AST.equal?({name, meta, nil}, selection) ->
        false

      not Module.inside_one?(zipper) ->
        false

      not Guard.guard_statement?(zipper) ->
        false

      is_nil(Guard.find_definition(zipper)) ->
        false

      true ->
        true
    end
  end

  def can_refactor?(_, _), do: false

  def refactor(%{node: {name, _, args}} = zipper, _) do
    case Guard.find_definition(zipper) do
      {:defguard, _, [{:when, _, [{_, _, args}, body]} = public_guard]} ->
        zipper
        |> Guard.new_private_guard(placeholder(), args, body)
        |> redirect_public_to_private_guard(public_guard)
        |> rename_references(name, args)

      _private_guard ->
        rename_references(zipper, name, args)
    end
  end

  defp rename_references(zipper, name, args) do
    zipper
    |> Z.top()
    |> Z.traverse_while(fn
      %{node: {:defguard, _, [{:when, _, [{^name, _, guard_args}, _]}]}} = zipper
      when length(args) == length(guard_args) ->
        {:skip, zipper}

      %{node: {^name, meta, guard_args}} = zipper ->
        cond do
          length(args) != length(guard_args) ->
            {:cont, zipper}

          not Guard.guard_statement?(zipper) ->
            {:cont, zipper}

          true ->
            {:cont, Z.replace(zipper, {placeholder(), meta, guard_args})}
        end

      zipper ->
        {:cont, zipper}
    end)
  end

  defp redirect_public_to_private_guard(zipper, public_guard) do
    zipper
    |> AST.go_to_node(public_guard)
    |> Z.update(fn {:when, meta, [{_, _, args} = header, _]} ->
      {:when, meta, [header, {placeholder(), [], args}]}
    end)
  end
end
