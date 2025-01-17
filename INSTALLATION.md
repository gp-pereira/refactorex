# Installation

Discover how to install RefactorEx for your editor.

## Visual Studio Code

Install through either:
- VS Code Extensions tab: search for "RefactorEx"
- [VSCode Marketplace](https://marketplace.visualstudio.com/items?itemName=gp-pereira.refatorex)

## NeoVim

Install via the [refactorex.nvim](https://github.com/synic/refactorex.nvim/blob/main/README.md) plugin.

Soon available through __Mason__ - track progress [here](https://github.com/mason-org/mason-registry/pull/8368).

## Connect it yourself

If your editor is not listed above yet and it supports the LSP, you can try connecting them yourself!

After cloning the repo and `mix deps.get`, you should be setup to start the server.

```bash
# starts LSP server on specified port
./bin/start --port 3108

# starts LSP server on stdio
./bin/start --stdio
```

Now, investigate how your editor can connect with the LSP server over the chosen port or if it can start the RefactorEx process by itself.

If you manage to pull this off, please help others by adding your solution here.

Ad astra!