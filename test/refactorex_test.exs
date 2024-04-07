defmodule RefactorexServerTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  @buffer GenLSP.Buffer

  import GenLSP.Test

  setup %{tmp_dir: tmp_dir} do
    {:ok, port} = :inet.port(GenLSP.Buffer.comm_state(@buffer).lsocket)

    # Linking the lsp process to the test process
    # so a server crash will also crash the test
    lsp = start_supervised!({Refactorex, []})
    Process.link(lsp)

    server = %{lsp: lsp, port: port, buffer: @buffer}

    client = client(server)

    :ok =
      request(client, %{
        method: "initialize",
        id: 1,
        jsonrpc: "2.0",
        params: %{
          capabilities: %{},
          rootUri: "file://#{Path.absname(tmp_dir)}"
        }
      })

    [server: server, client: client, cwd: Path.absname(tmp_dir)]
  end

  test "can start the LSP server", %{server: server} do
    assert alive?(server)
  end

  test "can respond Initialize request" do
    assert_result(1, %{
      "capabilities" => %{
        "textDocumentSync" => %{},
        "codeActionProvider" => true
      },
      "serverInfo" => %{"name" => "Refactorex"}
    })
  end

  test "can received TextDocumentDidOpen and TextDocumentDidChange notifications", %{
    server: %{lsp: lsp},
    client: client
  } do
    :ok =
      notify(client, %{
        method: "textDocument/didOpen",
        jsonrpc: "2.0",
        params: %{
          textDocument: %{
            version: 1,
            uri: "foo.ex",
            languageId: "elixir",
            text: "defmodule Foo do\nend"
          }
        }
      })

    Process.sleep(10)

    assert %{
             assigns: %{documents: %{"foo.ex" => "defmodule Foo do\nend"}}
           } = :sys.get_state(lsp)

    :ok =
      notify(client, %{
        method: "textDocument/didChange",
        jsonrpc: "2.0",
        params: %{
          textDocument: %{version: 2, uri: "foo.ex"},
          contentChanges: [%{text: "defmodule Bar do\nend"}]
        }
      })

    Process.sleep(10)

    assert %{
             assigns: %{documents: %{"foo.ex" => "defmodule Bar do\nend"}}
           } = :sys.get_state(lsp)
  end
end
