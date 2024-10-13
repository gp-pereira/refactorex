defmodule Refactorex do
  use GenLSP

  alias GenLSP.Requests.{
    Initialize,
    CodeActionResolve,
    TextDocumentCodeAction,
    TextDocumentPrepareRename,
    TextDocumentRename,
    Shutdown
  }

  alias GenLSP.Notifications.{
    Exit,
    TextDocumentDidOpen,
    TextDocumentDidChange,
    TextDocumentDidClose
  }

  alias __MODULE__.{
    Diff,
    Logger,
    Parser,
    Refactor,
    Response
  }

  def start_link(args) do
    {args, opts} = Keyword.split(args, [])
    GenLSP.start_link(__MODULE__, args, opts)
  end

  @impl true
  def init(lsp, _args) do
    Logger.info(lsp, "Server started")
    {:ok, assign(lsp, documents: %{})}
  end

  @impl true
  def handle_request(request, lsp) do
    prevent_crash(
      lsp,
      &do_handle_request(request, &1),
      # add error invalid request?
      {:reply, nil, lsp}
    )
  end

  @impl true
  def handle_notification(notification, lsp) do
    prevent_crash(
      lsp,
      &do_handle_notification(notification, &1),
      {:noreply, lsp}
    )
  end

  def do_handle_request(%Initialize{params: %{root_uri: root_uri}}, lsp) do
    Logger.info(lsp, "Client connected")
    {:reply, Response.initialize(), assign(lsp, root_uri: root_uri)}
  end

  def do_handle_request(%Shutdown{}, lsp) do
    Logger.info(lsp, "Client disconnected")
    {:reply, nil, lsp}
  end

  def do_handle_request(%TextDocumentCodeAction{params: params}, lsp) do
    case params do
      %{
        context: %{trigger_kind: 1},
        text_document: %{uri: uri},
        range: range
      } ->
        case Parser.parse_inputs(lsp.assigns.documents[uri], range) do
          {:ok, zipper, selection_or_line} ->
            {
              :reply,
              zipper
              |> Refactor.available_refactorings(selection_or_line)
              |> Response.suggest_refactorings(uri, range),
              lsp
            }

          {:error, :parse_error} ->
            # add error
            # maybe an error response can be a better message
            {:reply, [], lsp}
        end

      _ ->
        # add error invalid request?
        {:reply, [], lsp}
    end
  end

  def do_handle_request(%CodeActionResolve{params: %{data: data}}, lsp) do
    %{module: module, uri: uri, range: range} = Parser.parse_metadata(data)

    original = lsp.assigns.documents[uri]

    case Parser.parse_inputs(original, range) do
      {:ok, zipper, selection_or_line} ->
        {
          :reply,
          zipper
          |> Refactor.refactor(selection_or_line, module)
          |> Diff.find_diffs_from_original(original)
          |> Response.perform_refactoring(uri),
          lsp
        }

      {:error, :parse_error} ->
        # add error
        {:reply, [], lsp}
    end
  end

  def do_handle_request(%TextDocumentPrepareRename{params: params}, lsp) do
    %{text_document: %{uri: uri}, position: position} = params

    range = Parser.position_to_range(lsp.assigns.documents[uri], position)

    case Parser.parse_inputs(lsp.assigns.documents[uri], range) do
      {:ok, zipper, selection} ->
        if Refactor.rename_available?(zipper, selection),
          do: {:reply, Response.send_rename_range(range), lsp},
          # add error ??
          else: {:reply, nil, lsp}

      {:error, :parse_error} ->
        # add error
        {:reply, [], lsp}
    end
  end

  def do_handle_request(%TextDocumentRename{params: params}, lsp) do
    %{
      text_document: %{uri: uri},
      position: position,
      new_name: new_name
    } = params

    original = lsp.assigns.documents[uri]
    range = Parser.position_to_range(original, position)

    case Parser.parse_inputs(original, range) do
      {:ok, zipper, selection} ->
        {
          :reply,
          zipper
          |> Refactor.rename(selection, new_name)
          |> Diff.find_diffs_from_original(original)
          |> Response.perform_renaming(uri),
          lsp
        }

      {:error, :parse_error} ->
        # add error
        {:reply, [], lsp}
    end
  end

  def do_handle_notification(%Exit{}, lsp) do
    if Mix.env() == :prod, do: System.halt(0)
    {:noreply, lsp}
  end

  def do_handle_notification(%TextDocumentDidOpen{params: params}, lsp) do
    %{uri: uri, text: text} = params.text_document

    {:noreply, replace_document(lsp, uri, text)}
  end

  def do_handle_notification(%TextDocumentDidChange{params: params}, lsp) do
    %{uri: uri} = params.text_document
    [%{text: text}] = params.content_changes

    {:noreply, replace_document(lsp, uri, text)}
  end

  def do_handle_notification(%TextDocumentDidClose{params: params}, lsp) do
    %{uri: uri} = params.text_document

    {:noreply, replace_document(lsp, uri, "")}
  end

  def do_handle_notification(_, lsp), do: {:noreply, lsp}

  defp replace_document(lsp, uri, text),
    do: put_in(lsp.assigns.documents[uri], text)

  defp prevent_crash(lsp, func, default) do
    try do
      func.(lsp)
    rescue
      e ->
        Logger.error(lsp, Exception.format(:error, e, __STACKTRACE__))
        default
    end
  end
end
