defmodule Refactorex do
  use GenLSP


  # alias GenLSP.ErrorResponse

  # alias GenLSP.Enumerations.{
  #   CodeActionKind,
  #   DiagnosticSeverity,
  #   ErrorCodes,
  #   TextDocumentSyncKind
  # }

  # alias GenLSP.Notifications.{
  #   Exit,
  #   Initialized,
  #   TextDocumentDidChange,
  #   TextDocumentDidOpen,
  #   TextDocumentDidSave
  # }

  # alias GenLSP.Requests.{Initialize, Shutdown, TextDocumentCodeAction}

  # alias GenLSP.Structures.{
  #   CodeActionContext,
  #   CodeActionOptions,
  #   CodeActionParams,
  #   CodeDescription,
  #   Diagnostic,
  #   DidOpenTextDocumentParams,
  #   InitializeParams,
  #   InitializeResult,
  #   Position,
  #   Range,
  #   SaveOptions,
  #   ServerCapabilities,
  #   TextDocumentIdentifier,
  #   TextDocumentItem,
  #   TextDocumentSyncOptions,
  #   WorkDoneProgressBegin,
  #   WorkDoneProgressEnd
  # }

  def start_link(args) do
    {args, opts} = Keyword.split(args, []) |>IO.inspect()
    GenLSP.start_link(__MODULE__, args, opts)
  end

  @impl true
  def init(lsp, args) do
    # some_arg = Keyword.fetch!(args, :some_arg)
    IO.inspect("init called")

    {:ok, lsp}
  end

  # @impl true
  # def handle_request(%Initialize{params: %InitializeParams{root_uri: root_uri}}, lsp) do
  #   IO.inspect("heheh")

  #   {:reply,
  #    %InitializeResult{
  #      capabilities: %ServerCapabilities{
  #        text_document_sync: %TextDocumentSyncOptions{
  #          open_close: true,
  #          save: %SaveOptions{include_text: true},
  #          change: TextDocumentSyncKind.full()
  #        }
  #      },
  #      server_info: %{name: "MyLSP"}
  #    }, assign(lsp, root_uri: root_uri)}
  # end
end
