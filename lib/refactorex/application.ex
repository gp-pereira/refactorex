defmodule Refactorex.Application do
  use Application

  @default_port 6890

  def start(_, _) do
    Supervisor.start_link(
      [
        {
          GenLSP.Buffer,
          [communication: communication_config()]
        },
        {Refactorex.Logger, []},
        {Refactorex.NameCache, []},
        {Refactorex, []},
        {Task.Supervisor, [name: Refactorex.Refactor]}
      ],
      strategy: :one_for_one,
      name: Refactorex.Supervisor
    )
  end

  defp communication_config do
    opts =
      System.argv()
      |> OptionParser.parse(strict: [port: :integer, stdio: :boolean])
      |> elem(0)

    if Keyword.get(opts, :stdio, false) do
      {GenLSP.Communication.Stdio, []}
    else
      {GenLSP.Communication.TCP, [port: Keyword.get(opts, :port, @default_port)]}
    end
  end
end
