defmodule Refactorex do
  use GenLSP

  alias GenLSP.Requests.{
    Initialize,
    TextDocumentCodeAction,
    CodeActionResolve,
    Shutdown
  }

  alias GenLSP.Notifications.{
    Exit,
    TextDocumentDidOpen,
    TextDocumentDidChange,
    TextDocumentDidClose
  }

  alias __MODULE__.{
    Refactor,
    Response
  }

  require Logger

  def start_link(args) do
    {args, opts} = Keyword.split(args, [])
    GenLSP.start_link(__MODULE__, args, opts)
  end

  @impl true
  def init(lsp, _args) do
    Logger.info("Starting server")
    {:ok, assign(lsp, documents: %{})}
  end

  @impl true
  def handle_request(%Initialize{params: %{root_uri: root_uri}}, lsp) do
    Logger.info("Client connected")
    {:reply, Response.initialize(), assign(lsp, root_uri: root_uri)}
  end

  @impl true
  def handle_request(%TextDocumentCodeAction{params: params}, lsp) do
    case params do
      %{
        context: %{trigger_kind: 1},
        text_document: %{uri: uri},
        range: range
      } ->
        range = update_in(range.start.line, &(&1 + 1))
        range = update_in(range.end.line, &(&1 + 1))

        {
          :reply,
          lsp.assigns.documents[uri]
          |> Refactor.available_refactorings(range)
          |> Response.suggest_refactorings(uri, range),
          lsp
        }

      _ ->
        {:reply, [], lsp}
    end
  end

  @impl true
  def handle_request(%CodeActionResolve{params: params}, lsp) do
    %{module: module, uri: uri, range: range} = atom_map(params.data)

    {
      :reply,
      lsp.assigns.documents[uri]
      |> Refactor.refactor(range, module)
      |> Response.perform_refactoring(uri),
      lsp
    }
  end

  @impl true
  def handle_request(%Shutdown{}, lsp) do
    Logger.info("Client disconnected")
    {:reply, nil, lsp}
  end

  @impl true
  def handle_notification(%Exit{}, lsp) do
    System.halt(0)
    {:noreply, lsp}
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
  def handle_notification(%TextDocumentDidClose{params: params}, lsp) do
    %{uri: uri} = params.text_document

    {:noreply, replace_document(lsp, uri, "")}
  end

  @impl true
  def handle_notification(_, lsp), do: {:noreply, lsp}

  defp replace_document(lsp, uri, text),
    do: put_in(lsp.assigns.documents[uri], text)

  defp atom_map(%{} = map) do
    map
    |> Enum.map(fn {k, v} -> {String.to_atom(k), atom_map(v)} end)
    |> Map.new()
  end

  defp atom_map(not_map), do: not_map
end
