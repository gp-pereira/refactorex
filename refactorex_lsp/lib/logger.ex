defmodule RefactorexLSP.Logger do
  use Agent

  require Logger

  def start_link(_), do: Agent.start_link(fn -> nil end, name: __MODULE__)

  def set_lsp(lsp), do: Agent.update(__MODULE__, fn _ -> lsp end)

  def info(message) do
    Logger.info(message)

    if Mix.env() != :test do
      Agent.get(__MODULE__, &if(&1, do: GenLSP.info(&1, message)))
    end
  end

  def error(reason) do
    message = Exception.format_exit(reason)
    Logger.error(message)

    if Mix.env() != :test do
      Agent.get(__MODULE__, &if(&1, do: GenLSP.error(&1, message)))
    end
  end
end
