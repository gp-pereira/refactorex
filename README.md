# Refactorex for VS Code

Uses the [Refactorex](https://github.com/gp-pereira/refactorex) language server to 
enhance VS Code with code actions to quickly refactor Elixir. 

![Example](https://github.com/gp-pereira/refactorex-vscode/blob/main/assets/examples/readme.gif?raw=true)

## Available refactorings

| Scope | Refactoring | Target | Published? |
| :-: | - | :-: | :-: |
| `alias` | Extract alias | selection | |
| `alias` | Expand aliases | selection | |
| `alias` | Inline alias | selection | |
| `alias` | Merge aliases | selection | |
| `alias` | Sort nested aliases | line | ✅ |
| | | |
| `constant` | [Extract constant](#variable-extract-constant) | selection | ✅ |
| `constant` | Inline constant | selection | ✅ |
| `constant` | Rename constant | selection | ✅ |
| | | |
| `function` | [Expand anonymous function](#function-expand-anonymous-function) | selection | ✅ |
| `function` | [Extract anonymous function](#function-extract-anonymous-function) | selection | ✅ |
| `function` | [Extract function](#function-extract-function) | selection | ✅ |
| `function` | Collapse anonymous function | selection | ✅ |
| `function` | Inline function | selection | ✅ |
| `function` | Rename function | selection | ✅ |
| `function` | [Underscore unused args](#function-underscore-unused-args) | line | ✅ |
| `function` | [Use keyword syntax](#function-use-keyword-syntax) | line | ✅ |
| `function` | [Use regular syntax](#function-use-regular-syntax) | line | ✅ |
| | | |
| `guard` | Extract guard | selection | ✅ |
| `guard` | Inline guard | selection | ✅ |
| `guard` | Rename guard | selection | ✅ |
| | | |
| `if else` | Use keyword syntax | line | ✅ |
| `if else` | Use regular syntax | line | ✅ |
| | | |
| `pipeline` | Introduce IO.inspect | selection | ✅ |
| `pipeline` | [Introduce pipe](#pipeline-pipe-first-arg) | line |  ✅ |
| `pipeline` | Remove IO.inspect | line | ✅ |
| `pipeline` | [Remove pipe](#pipeline-remove-pipe) | line | ✅ |
| | | |
| `variable` | Extract variable | selection | ✅ |
| `variable` | Inline variable | selection | ✅ |
| `variable` | Rename variable | selection | ✅ |

## How to use each refactoring

### Function: expand anonymous function

* __Description__: expand an anonymous function from & to fn -> end syntax
* __Works on__: anonymous function selection

![Example](https://github.com/gp-pereira/refactorex-vscode/blob/main/assets/examples/function/expand_anonymous_function.gif?raw=true)

[▲ top](#available-refactorings)

<br>

### Function: extract anonymous function

* __Description__: extract the anonymous function into a private function
* __Works on__: anonymous function selection

![Example](https://github.com/gp-pereira/refactorex-vscode/blob/main/assets/examples/function/extract_anonymous_function.gif?raw=true)


[▲ top](#available-refactorings)

<br>

### Function: extract function

* __Description__: extract the selection into a private function
* __Works on__: selection

![Example](https://github.com/gp-pereira/refactorex-vscode/blob/main/assets/examples/function/extract_function.gif?raw=true)

[▲ top](#available-refactorings)

<br>


### Variable: underscore unused args

* __Description__: places an underscore in front of function args not used.
* __Works on__: function definition line or function clause line

![Example](https://github.com/gp-pereira/refactorex-vscode/blob/main/assets/examples/function/underscore_unused_args.gif?raw=true)

[▲ top](#available-refactorings)

<br>

### Function: use keyword syntax

* __Description__: rewrite the regular function (do end) using keyword syntax (, do:)
* __Works on__: function definition line

![Example](https://github.com/gp-pereira/refactorex-vscode/blob/main/assets/examples/function/use_keyword_syntax.gif?raw=true)

[▲ top](#available-refactorings)

<br>

### Function: use regular syntax

* __Description__: rewrite the keyword function (, do:) using regular syntax (do end)
* __Works on__: function definition line

![Example](https://github.com/gp-pereira/refactorex-vscode/blob/main/assets/examples/function/use_regular_syntax.gif?raw=true)

[▲ top](#available-refactorings)

<br>

### Pipeline: pipe first arg

* __Description__: pipe the first arg into call
* __Works on__: line

![Example](https://github.com/gp-pereira/refactorex-vscode/blob/main/assets/examples/pipeline/pipe_first_arg.gif?raw=true)

[▲ top](#available-refactorings)

<br>

### Pipeline: remove pipe

* __Description__: remove the pipe operator and put first arg inside call
* __Works on__: pipe line

![Example](https://github.com/gp-pereira/refactorex-vscode/blob/main/assets/examples/pipeline/remove_pipe.gif?raw=true)

[▲ top](#available-refactorings)

<br>

### Variable: extract constant

* __Description__: extract the selection into a module constant
* __Works on__: selection

![Example](https://github.com/gp-pereira/refactorex-vscode/blob/main/assets/examples/variable/extract_constant.gif?raw=true)

[▲ top](#available-refactorings)

<br>
