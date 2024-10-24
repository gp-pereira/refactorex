# Refactorex

Refactorex is a TCP server that implements the Language Server Protocol
to enhance editors with Elixir refactoring code actions, inspired on the 
[catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings)

- [VS Code extension](https://github.com/gp-pereira/refactorex-vscode)

## How it works

```mermaid
sequenceDiagram 
	participant A as Editor
	participant B as LanguageServer
	participant C as All Refactors
	participant D as Selected Refactor
	
	A--)B: file opened
	A->>B: show refactorings for line or selection
	B->>C: can refactor line or selection?
	C-->>B: yes or no
	B-->>A: list of available refactorings
	
	A->>B: use this refactoring
	B->>D: refactor line or selection
	D-->>B: refactored code
	B-->>A: file diffs
```

## Acknowledgements

- [Sourceror](https://github.com/doorgan/sourceror) which made traversing and updating the Elixir AST super simple
- [GenLSP](https://github.com/elixir-tools/gen_lsp) for providing much of the infrastructure to create an Elixir language server