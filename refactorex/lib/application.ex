defmodule Refactorex.Application do
  use Application

  def start(_, _) do
    Supervisor.start_link(
      [
        {Refactorex.NameCache, []},
        {Task.Supervisor, [name: Refactorex.Refactor]}
      ],
      strategy: :one_for_one,
      name: Refactorex.Supervisor
    )
  end
end
