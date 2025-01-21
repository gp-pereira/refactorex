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
    NameCache,
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
    Logger.info("Server started")
    {:ok, assign(lsp, documents: %{})}
  end

  @impl true
  def handle_notification(%Exit{}, _lsp) do
    Logger.info("Server stopped")
    System.halt(0)
  end

  @impl true
  def handle_notification(%TextDocumentDidOpen{params: params}, lsp) do
    %{uri: uri, text: text} = params.text_document
    {:noreply, put_in(lsp.assigns.documents[uri], text)}
  end

  @impl true
  def handle_notification(%TextDocumentDidChange{params: params}, lsp) do
    %{uri: uri} = params.text_document
    [%{text: text}] = params.content_changes
    {:noreply, put_in(lsp.assigns.documents[uri], text)}
  end

  @impl true
  def handle_notification(%TextDocumentDidClose{params: params}, lsp) do
    %{uri: uri} = params.text_document
    {:noreply, put_in(lsp.assigns.documents[uri], "")}
  end

  @impl true
  def handle_notification(_, lsp), do: {:noreply, lsp}

  @impl true
  def handle_request(request, lsp) do
    try do
      case do_handle_request(request, lsp) do
        {:ok, reply} -> {:reply, reply, lsp}
        {:error, error} -> {:reply, Response.error(error), lsp}
      end
    rescue
      e ->
        Logger.error({e, __STACKTRACE__})
        {:reply, Response.error(:internal_error), lsp}
    end
  end

  def do_handle_request(%Initialize{}, lsp) do
    Logger.set_lsp(lsp)
    Logger.info("Client connected")
    {:ok, Response.initialize()}
  end

  def do_handle_request(%Shutdown{}, _lsp) do
    Logger.set_lsp(nil)
    Logger.info("Client disconnected")
    {:ok, nil}
  end

  def do_handle_request(%TextDocumentCodeAction{params: params}, lsp) do
    case params do
      %{
        context: %{trigger_kind: 1},
        text_document: %{uri: uri},
        range: range
      } ->
        original = lsp.assigns.documents[uri]

        case Parser.parse_inputs(original, range) do
          {:ok, zipper, selection_or_line} ->
            {
              :ok,
              zipper
              |> Refactor.available_refactorings(selection_or_line)
              |> Response.suggest_refactorings(uri, range)
            }

          {:error, :parse_error} ->
            {:ok, []}
        end

      _ ->
        {:ok, []}
    end
  end

  def do_handle_request(%CodeActionResolve{params: %{data: data}}, lsp) do
    %{module: module, uri: uri, range: range} = metadata = Parser.parse_metadata(data)

    original = lsp.assigns.documents[uri]
    NameCache.store_name(metadata[:new_name])

    with {:ok, zipper, selection_or_line} <- Parser.parse_inputs(original, range) do
      {
        :ok,
        zipper
        |> Refactor.refactor(selection_or_line, module)
        |> Diff.from_original(original)
        |> Response.perform_refactoring(uri)
      }
    end
  end

  def do_handle_request(%TextDocumentPrepareRename{params: params}, lsp) do
    %{text_document: %{uri: uri}, position: position} = params

    original = lsp.assigns.documents[uri]
    range = Parser.position_to_range(original, position)

    case Parser.parse_inputs(original, range) do
      {:ok, zipper, selection} ->
        cond do
          not Refactor.rename_available?(zipper, selection) ->
            {:ok, nil}

          match?({:@, _, _}, selection) ->
            # this is done so that the placeholder
            # for RenameConstant doesn't include the @
            range = update_in(range.start.character, &(&1 + 1))
            {:ok, Response.send_rename_range(range)}

          true ->
            {:ok, Response.send_rename_range(range)}
        end

      {:error, :parse_error} ->
        {:ok, nil}
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

    with {:ok, zipper, selection} <- Parser.parse_inputs(original, range) do
      {
        :ok,
        zipper
        |> Refactor.rename(selection, new_name)
        |> Diff.from_original(original)
        |> Response.perform_renaming(uri)
      }
    end
  end
end
