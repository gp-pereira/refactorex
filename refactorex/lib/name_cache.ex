defmodule Refactorex.NameCache do
  use Agent

  def start_link(_), do: Agent.start_link(fn -> nil end, name: __MODULE__)

  def store_name(new_name) when is_bitstring(new_name) do
    new_name
    |> String.replace(~r/[^a-zA-Z0-9_?!]/, "")
    |> String.to_atom()
    |> store_name()
  end

  def store_name(new_name), do: Agent.update(__MODULE__, fn _ -> new_name end)

  def consume_name_or(namer_fn),
    do: Agent.get_and_update(__MODULE__, &{&1 || namer_fn.(), nil})
end
