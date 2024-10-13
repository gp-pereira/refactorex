defmodule Refactorex.Logger do
  require Logger

  def info(lsp, message) do
    if connected?(lsp), do: GenLSP.info(lsp, message)
    Logger.info(message)
  end

  def error(lsp, message) do
    if connected?(lsp), do: GenLSP.error(lsp, message)
    Logger.error(message)
  end

  def connected?(lsp), do: match?(%{socket: _}, lsp)
end
