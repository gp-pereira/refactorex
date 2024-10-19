defmodule Refactorex.Refactor.Guard.ExtractGuard do
  use Refactorex.Refactor,
    title: "Extract private guard",
    kind: "refactor.extract",
    works_on: :selection

  alias Refactorex.Refactor.{
    Function,
    Guard,
    Module,
    Variable
  }

  @guard_name "extracted_guard"

  def can_refactor?(%{node: node} = zipper, selection) do
    cond do
      not AST.equal?(node, selection) ->
        false

      not Module.inside_one?(zipper) ->
        false

      not Guard.guard_statement?(zipper) ->
        false

      true ->
        true
    end
  end

  def refactor(%{node: node} = zipper, _) do
    name = next_available_guard_name(zipper)
    args = Variable.find_variables(node)

    zipper
    |> Z.replace({name, [], args})
    |> Module.update_scope(fn module_scope ->
      {before, rest} = where_to_place_guard(module_scope)

      before ++ [{:defguardp, [], [{:when, [], [{name, [], args}, node]}]} | rest]
    end)
  end

  defp next_available_guard_name(zipper) do
    Module.next_available_name(
      zipper,
      @guard_name,
      &match?({id, _, _} when id in ~w(defguard defguardp)a, &1),
      fn {_, _, [{:when, _, [{name, _, _} | _]}]} -> name end
    )
  end

  defp where_to_place_guard(module_scope) do
    module_scope
    |> Enum.find_index(&Function.definition?/1)
    |> then(&Enum.split(module_scope, &1 || 0))
  end
end
