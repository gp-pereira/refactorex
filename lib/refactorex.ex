defmodule Refactorex do
  use GenLSP

  alias GenLSP.Requests.{
    Initialize,
    TextDocumentCodeAction
  }

  alias GenLSP.Notifications.{
    TextDocumentDidOpen,
    TextDocumentDidChange
  }

  alias __MODULE__.Response

  require Logger

  def start_link(args) do
    {args, opts} = Keyword.split(args, [])
    GenLSP.start_link(__MODULE__, args, opts)
  end

  @impl true
  def init(lsp, _args) do
    Logger.info("Starting Refactorex server")
    {:ok, assign(lsp, documents: %{})}
  end

  @impl true
  def handle_request(%Initialize{params: %{root_uri: root_uri}}, lsp) do
    {:reply, Response.initialize(), assign(lsp, root_uri: root_uri)}
  end

  @impl true
  def handle_request(%TextDocumentCodeAction{} = r, lsp) do
    IO.inspect(r.method, label: "request")

    {:reply, Response.code_actions(), lsp}
  end

  @impl true
  def handle_notification(%TextDocumentDidOpen{params: params}, lsp) do
    %{uri: uri, text: text} = params.text_document

    {:noreply, replace_document(lsp, uri, text)}
  end

  @impl true
  def handle_notification(%TextDocumentDidChange{params: params}, lsp) do
    %{uri: uri} = params.text_document
    [%{text: text}] = params.content_changes

    {:noreply, replace_document(lsp, uri, text)}
  end

  @impl true
  def handle_notification(r, lsp) do
    IO.inspect(r.method, label: "notification")
    Logger.info("git here")

    {:noreply, lsp}
  end

  defp replace_document(lsp, uri, text),
    do: put_in(lsp.assigns.documents[uri], text)
end
