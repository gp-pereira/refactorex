defmodule Refactorex.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {
        GenLSP.Buffer,
        [communication: {GenLSP.Communication.TCP, [port: 9000]}]
      },
      {Refactorex, []}
    ]

    opts = [strategy: :one_for_one, name: Refactorex.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
