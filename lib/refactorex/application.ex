defmodule Refactorex.Application do
  use Application

  @default_port 6890

  @impl true
  def start(_, _) do
    children = [
      {
        GenLSP.Buffer,
        [communication: {GenLSP.Communication.TCP, [port: port()]}]
      },
      {Refactorex.Logger, []},
      {Refactorex, []}
    ]

    opts = [strategy: :one_for_one, name: Refactorex.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp port do
    System.argv()
    |> OptionParser.parse(strict: [port: :integer])
    |> elem(0)
    |> Keyword.get(:port, @default_port)
  end
end
