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
        code_action_provider: %Structures.CodeActionOptions{
          resolve_provider: true
        },
        rename_provider: %Structures.RenameOptions{
          prepare_provider: true
        }
      }
    }
  end

  def suggest_refactorings(refactorings, uri, range) do
    Enum.map(refactorings, fn refactoring ->
      %Structures.CodeAction{
        title: refactoring.title,
        kind: refactoring.kind,
        data: %{
          module: refactoring.module,
          range: range,
          uri: uri
        }
      }
    end)
  end

  def perform_refactoring(refactoring, uri) do
    %Structures.CodeAction{
      title: refactoring.title,
      kind: refactoring.kind,
      edit: %Structures.WorkspaceEdit{
        changes: %{
          uri =>
            Enum.map(
              refactoring.diffs,
              &%Structures.TextEdit{
                new_text: &1.text,
                range: %Structures.Range{
                  start: %Structures.Position{
                    line: &1.range.start.line,
                    character: &1.range.start.character
                  },
                  end: %Structures.Position{
                    line: &1.range.end.line,
                    character: &1.range.end.character
                  }
                }
              }
            )
        }
      }
    }
  end

  def perform_renaming(refactoring, uri) do
    %Structures.WorkspaceEdit{
      changes: %{
        uri =>
          Enum.map(
            refactoring.diffs,
            &%Structures.TextEdit{
              new_text: &1.text,
              range: %Structures.Range{
                start: %Structures.Position{
                  line: &1.range.start.line,
                  character: &1.range.start.character
                },
                end: %Structures.Position{
                  line: &1.range.end.line,
                  character: &1.range.end.character
                }
              }
            }
          )
      }
    }
  end

  def send_rename_range(range) do
    %Structures.Range{
      start: %Structures.Position{
        line: range.start.line,
        character: range.start.character
      },
      end: %Structures.Position{
        line: range.end.line,
        character: range.end.character
      }
    }
  end
end
