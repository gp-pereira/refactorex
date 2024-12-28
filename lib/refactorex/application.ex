defmodule Refactorex.Application do
  use Application

  @default_port 6890

  @impl true
  def start(_, _) do
    Supervisor.start_link(
      [
        {
          GenLSP.Buffer,
          [communication: communication_config()]
        },
        {Refactorex.Logger, []},
        {Refactorex.NameCache, []},
        {Refactorex, []}
      ],
      strategy: :one_for_one,
      name: Refactorex.Supervisor
    )
  end

  defp parse_opts do
    System.argv()
    |> OptionParser.parse(strict: [port: :integer, stdio: :boolean])
    |> elem(0)
  end

  defp port do
    parse_opts()
    |> Keyword.get(:port, @default_port)
  end

  defp communication_config do
    opts = parse_opts()

    if Keyword.get(opts, :stdio, false) do
      {GenLSP.Communication.Stdio, []}
    else
      {GenLSP.Communication.TCP, [port: port()]}
    end
  end
end
