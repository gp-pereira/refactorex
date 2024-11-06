defmodule Refactorex.Refactor.Guard do
  alias Sourceror.Zipper, as: Z

  alias Refactorex.Refactor.{
    Function,
    Module
  }

  def definition?({:defguard, _, _}), do: true
  def definition?({:defguardp, _, _}), do: true
  def definition?(_), do: false

  def find_definition(%{node: {name, _, args}} = zipper) do
    zipper
    |> Module.find_in_scope(fn
      {_, _, [{:when, _, [{^name, _, guard_args}, _]}]} = node ->
        definition?(node) and length(args) == length(guard_args)

      _ ->
        false
    end)
    |> List.first()
  end

  def guard_statement?(zipper) do
    case parent = Z.up(zipper) do
      %{node: {:when, _, _}} ->
        true

      %{node: {id, _, _}} when id in ~w(and or not)a ->
        guard_statement?(parent)

      _ ->
        false
    end
  end

  def new_private_guard(zipper, name, args, body) do
    private_guard = {:defguardp, [], [{:when, [], [{name, [], args}, body]}]}

    Module.update_scope(zipper, fn module_scope ->
      {before, rest} = where_to_place_guard(module_scope)
      before ++ [private_guard | rest]
    end)
  end

  defp where_to_place_guard(module_scope) do
    module_scope
    |> Enum.find_index(&(Function.definition?(&1) or definition?(&1)))
    |> then(&Enum.split(module_scope, &1 || 0))
  end
end
