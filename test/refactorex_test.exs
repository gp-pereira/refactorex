defmodule RefactorexTest do
  use ExUnit.Case, async: true

  import GenLSP.Test

  @moduletag :tmp_dir

  @buffer GenLSP.Buffer
  @timeout 200

  setup %{tmp_dir: tmp_dir} do
    {:ok, port} = :inet.port(GenLSP.Buffer.comm_state(@buffer).lsocket)

    # Linking the lsp process to the test process
    # so a server crash will also crash the test
    lsp = start_supervised!({Refactorex, []})
    Process.link(lsp)

    server = %{lsp: lsp, port: port, buffer: @buffer}

    client = client(server)

    root_uri = "file://#{Path.absname(tmp_dir)}"
    file_uri = "#{root_uri}/foo.ex"

    :ok =
      request(client, %{
        "method" => "initialize",
        "id" => 1,
        "jsonrpc" => "2.0",
        "params" => %{
          "capabilities" => %{},
          "rootUri" => file_uri
        }
      })

    :ok =
      notify(client, %{
        method: "textDocument/didOpen",
        jsonrpc: "2.0",
        params: %{
          textDocument: %{
            version: 1,
            languageId: "elixir",
            uri: file_uri,
            text: """
            defmodule Foo do
              def bar(arg) do
                arg
              end
            end
            """
          }
        }
      })

    [server: server, client: client, file_uri: file_uri]
  end

  test "starts the LSP server", %{server: server} do
    assert alive?(server)
  end

  test "responds Initialize request" do
    assert_result(
      1,
      %{
        "capabilities" => %{
          "textDocumentSync" => %{},
          "codeActionProvider" => %{"resolveProvider" => true}
        },
        "serverInfo" => %{"name" => "Refactorex"}
      },
      @timeout
    )
  end

  test "responds CodeActions refactorings for some file", %{
    client: client,
    file_uri: file_uri
  } do
    :ok = request_code_actions(client, file_uri)

    assert_result(
      2,
      [
        %{
          "title" => "Rewrite function using keyword syntax",
          "kind" => "refactor.rewrite",
          "data" => %{
            "module" => "Elixir.Refactorex.Refactor.Function.UseKeywordSyntax",
            "uri" => ^file_uri,
            "range" => %{
              "start" => %{"line" => 2, "character" => 4},
              "end" => %{"line" => 2, "character" => 4}
            }
          }
        } = code_action
      ],
      @timeout
    )

    :ok =
      request(client, %{
        method: "codeAction/resolve",
        id: 3,
        jsonrpc: "2.0",
        params: code_action
      })

    assert_result(
      3,
      %{
        "title" => "Rewrite function using keyword syntax",
        "kind" => "refactor.rewrite",
        "edit" => %{
          "changes" => %{
            ^file_uri => [
              %{
                "newText" => "  def bar(arg), do: arg",
                "range" => %{
                  "end" => %{"character" => 5, "line" => 3},
                  "start" => %{"character" => 0, "line" => 1}
                }
              }
            ]
          }
        }
      },
      @timeout
    )
  end

  test "responds no CodeActions for syntactically broken file", %{
    client: client,
    file_uri: file_uri
  } do
    :ok =
      notify(client, %{
        method: "textDocument/didChange",
        jsonrpc: "2.0",
        params: %{
          textDocument: %{version: 2, uri: file_uri},
          contentChanges: [%{text: "defmodule Foo do\nend\nend"}]
        }
      })

    :ok = request_code_actions(client, file_uri)

    assert_result(2, [], @timeout)
  end

  defp request_code_actions(client, file_uri) do
    request(client, %{
      method: "textDocument/codeAction",
      id: 2,
      jsonrpc: "2.0",
      params: %{
        textDocument: %{uri: file_uri},
        range: %{
          start: %{line: 1, character: 4},
          end: %{line: 1, character: 4}
        },
        context: %{
          diagnostics: [],
          triggerKind: 1
        }
      }
    })
  end
end
