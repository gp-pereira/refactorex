defmodule Refactorex.Application do
  use Application

  @default_port 6890

  @impl true
  def start(_, _) do
    Supervisor.start_link(
      [
        {
          GenLSP.Buffer,
          [communication: {GenLSP.Communication.TCP, [port: port()]}]
        },
        {Refactorex.Logger, []},
        {Refactorex.NameCache, []},
        {Refactorex, []}
      ],
      strategy: :one_for_one,
      name: Refactorex.Supervisor
    )
  end

  defp port do
    System.argv()
    |> OptionParser.parse(strict: [port: :integer])
    |> elem(0)
    |> Keyword.get(:port, @default_port)
  end
end
