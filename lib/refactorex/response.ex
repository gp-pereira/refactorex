defmodule Refactorex.Response do
  alias GenLSP.{
    Enumerations,
    Structures
  }

  def initialize do
    %Structures.InitializeResult{
      server_info: %{name: "Refactorex"},
      capabilities: %Structures.ServerCapabilities{
        text_document_sync: %Structures.TextDocumentSyncOptions{
          open_close: true,
          save: %Structures.SaveOptions{include_text: true},
          change: Enumerations.TextDocumentSyncKind.full()
        },
        code_action_provider: true
      }
    }
  end

  def code_actions do
    [
      %Structures.CodeAction{
        title: "my_first_action"
      },
      %Structures.CodeAction{
        title: "my_second_action"
      }
    ]
  end
end
