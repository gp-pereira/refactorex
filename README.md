# RefactorEx

RefactorEx is a powerful editor plugin extension that simplifies and accelerates code refactoring for Elixir projects. It introduces intuitive code actions to help you refactor Elixir code efficiently and confidently.

With RefactorEx, you can perform common refactorings like extracting functions, renaming variables, and more — all within a few clicks.

![Example](assets/examples/demo.gif?raw=true)

You can check all supported editors in our [installation guide](INSTALLATION.md).

## Available refactorings

| Scope | Refactoring | Target | Command |
| :-: | - | - | - |
| `alias` | [Expand aliases](#alias-expand-aliases) | selection | refactor (`ctrl`+`.`)|
| `alias` | [Extract alias](#alias-extract-alias) | selection | refactor (`ctrl`+`.`) |
| `alias` | [Inline alias](#alias-inline-alias) | selection | refactor (`ctrl`+`.`) |
| `alias` | [Merge aliases](#alias-merge-aliases) | selection | refactor (`ctrl`+`.`) |
| `alias` | [Sort nested aliases](#alias-sort-nested-aliases) | line | refactor (`ctrl`+`.`) |
| | | |
| `constant` | [Extract constant](#constant-extract-constant) | selection | refactor (`ctrl`+`.`) |
| `constant` | [Inline constant](#constant-inline-constant) | selection | refactor (`ctrl`+`.`) |
| `constant` | [Rename constant](#constant-rename-constant) | at symbol | rename (`F2`) |
| | | |
| `function` | [Expand anonymous function](#function-expand-anonymous-function) | selection | refactor (`ctrl`+`.`) |
| `function` | [Extract anonymous function](#function-extract-anonymous-function) | selection | refactor (`ctrl`+`.`) |
| `function` | [Extract function](#function-extract-function) | selection | refactor (`ctrl`+`.`) |
| `function` | [Collapse anonymous function](#function-collapse-anonymous-function) | selection | refactor (`ctrl`+`.`) |
| `function` | [Inline function](#function-inline-function) | selection | refactor (`ctrl`+`.`) |
| `function` | [Rename function](#function-rename-function) | at symbol | rename (`F2`) |
| `function` | [Underscore unused args](#function-underscore-unused-args) | line | refactor (`ctrl`+`.`) |
| `function` | [Use keyword syntax](#function-use-keyword-syntax) | line | refactor (`ctrl`+`.`) |
| `function` | [Use regular syntax](#function-use-regular-syntax) | line | refactor (`ctrl`+`.`) |
| | | |
| `guard` | [Extract guard](#guard-extract-guard) | selection | refactor (`ctrl`+`.`) |
| `guard` | [Inline guard](#guard-inline-guard) | selection | refactor (`ctrl`+`.`) |
| `guard` | [Rename guard](#guard-rename-guard) | at symbol | rename (`F2`) |
| | | |
| `if else` | [Use keyword syntax](#if-else-use-keyword-syntax) | line | refactor (`ctrl`+`.`) |
| `if else` | [Use regular syntax](#if-else-use-regular-syntax) | line | refactor (`ctrl`+`.`) |
| | | |
| `pipeline` | [Introduce IO.inspect](#pipeline-introduce-ioinspect) | selection | refactor (`ctrl`+`.`) |
| `pipeline` | [Introduce pipe](#pipeline-introduce-pipe) | line | refactor (`ctrl`+`.`) | 
| `pipeline` | [Remove IO.inspect](#pipeline-remove-ioinspect) | line | refactor (`ctrl`+`.`) |
| `pipeline` | [Remove pipe](#pipeline-remove-pipe) | line | refactor (`ctrl`+`.`) |
| | | |
| `variable` | [Extract variable](#variable-extract-variable) | selection | refactor (`ctrl`+`.`) |
| `variable` | [Inline variable](#variable-inline-variable) | selection | refactor (`ctrl`+`.`) |
| `variable` | [Rename variable](#variable-rename-variable) | at symbol | rename (`F2`) |

## How to use each refactoring

### Alias: expand aliases

| | |
|-|-|
| Description | Expand nested `aliases` to their full names |
| Target | Selection of nested `alias`, group of nested `aliases` or `alias` with nesting |
| Inverse of | [Merge aliases](#alias-merge-aliases) |
| Read more | [Catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings?tab=readme-ov-file#alias-expansion) |
| Example | ![Example](assets/examples/alias/expand_aliases.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Alias: extract alias

| | |
|-|-|
| Description | Extract the module full name into an `alias` and use it |
| Target | Selection of module full name |
| Inverse of | [Inline alias](#alias-inline-alias) |
| Example | ![Example](assets/examples/alias/extract_alias.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Alias: inline alias

| | |
|-|-|
| Description | Replace the `alias` usage by the module full name |
| Target | Selection of `alias` usage |
| Inverse of | [Extract alias](#alias-extract-alias) |
| Notes | 1. `alias` must be declared on the same module <br> 2. `alias` declaration will not be removed |
| Example | ![Example](assets/examples/alias/inline_alias.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Alias: merge aliases

| | |
|-|-|
| Description | Merge the group of `aliases` into a nested alias |
| Target | Selection of two or more mergeable `aliases` |
| Inverse of | [Expand aliases](#alias-expand-aliases) |
| Example | ![Example](assets/examples/alias/merge_aliases.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Alias: sort nested aliases

| | |
|-|-|
| Description | Sort all nested `aliases` alphabetically |
| Target | Line of `alias` with unsorted nested `aliases` |
| Example | ![Example](assets/examples/alias/sort_nested_aliases.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Constant: extract constant

| | |
|-|-|
| Description | Extract a piece of code into a `constant` |
| Target | Selection of any code without `variables` |
| Inverse of | [Inline constant](#constant-inline-constant) |
| Read more | [Catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings?tab=readme-ov-file#extract-constant) |
| Example | ![Example](assets/examples/constant/extract_constant.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Constant: inline constant

| | |
|-|-|
| Description | Replace a `constant` usage by its value |
| Target | Selection of `constant` |
| Inverse of | [Extract constant](#constant-extract-constant) |
| Notes | 1. `constant` must be declared on the same module <br> 2. `constant` declaration will not be removed |
| Example | ![Example](assets/examples/constant/inline_constant.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Constant: rename constant

| | |
|-|-|
| Description | Replace the name of `constant` in all its usages |
| Target | Cursor at `constant` definition or usage |
| Read more | [Catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings?tab=readme-ov-file#rename-an-identifier) |
| Example | ![Example](assets/examples/constant/rename_constant.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Function: collapse anonymous function

| | |
|-|-|
| Description | Collapse a `fn` function into a `&` function |
| Target | Selection of `fn` function |
| Inverse of | [Expand anonymous function](#function-expand-anonymous-function) |
| Example | ![Example](assets/examples/function/collapse_anonymous_function.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Function: extract anonymous function

| | |
|-|-|
| Description | Extract a `&` or `fn` function into a `function` |
| Target | Selection of `&` or `fn` function |
| Inverse of | [Inline function](#function-inline-function) |
| Read more | [Catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings?tab=readme-ov-file#turning-anonymous-into-local-functions) |
| Example | ![Example](assets/examples/function/extract_anonymous_function.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Function: expand anonymous function

| | |
|-|-|
| Description | Expand a `&` function into a `fn` function |
| Target | Selection of `&` function |
| Inverse of | [Collapse anonymous function](#function-collapse-anonymous-function) |
| Example | ![Example](assets/examples/function/expand_anonymous_function.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Function: extract function

| | |
|-|-|
| Description | Extract a piece of code into a `function` |
| Target | Selection of any code |
| Inverse of | [Inline function](#function-inline-function) |
| Read more | [Catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings?tab=readme-ov-file#extract-function) |
| Example | ![Example](assets/examples/function/extract_function.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Function: inline function

| | |
|-|-|
| Description | Replace a `function` call by its body |
| Target | Selection of `function` call |
| Inverse of | [Extract anonymous function](#function-extract-anonymous-function), [Extract function](#function-extract-function) |
| Read more | [Catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings?tab=readme-ov-file#inline-function) |
| Notes | 1. `function` must be defined on the same module <br> 2. `function` definition will not be removed |
| Example | ![Example](assets/examples/function/inline_function.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Function: rename function

| | |
|-|-|
| Description | Replace the name of `function` in all its calls |
| Target | Cursor at `function` definition or usage |
| Read more | [Catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings?tab=readme-ov-file#rename-an-identifier) |
| Notes | ⚠️ Renaming a public `function` only affects the current file |
| Example | ![Example](assets/examples/function/rename_function.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Function: underscore unused args

| | |
|-|-|
| Description | Places a `_` in front of args not used |
| Target | Line of `function` definition with unused args |
| Example | ![Example](assets/examples/function/underscore_unused_args.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Function: use keyword syntax

| | |
|-|-|
| Description | Rewrite the `function` using keyword syntax |
| Target | Line of `function` definition using regular syntax |
| Inverse of | [Use regular syntax](#function-use-regular-syntax) |
| Notes | `function` body must have a single statement |
| Example | ![Example](assets/examples/function/use_keyword_syntax.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Function: use regular syntax

| | |
|-|-|
| Description | Rewrite the `function` using regular syntax |
| Target | Line of `function` definition using keyword syntax |
| Inverse of | [Use keyword syntax](#function-use-keyword-syntax) |
| Example | ![Example](assets/examples/function/use_regular_syntax.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Guard: extract guard

| | |
|-|-|
| Description | Extract a `when` statement into a `guard` |
| Target | Selection of `when` statement or part of one |
| Inverse of | [Inline guard](#guard-inline-guard) |
| Example | ![Example](assets/examples/guard/extract_guard.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Guard: inline guard

| | |
|-|-|
| Description | Replace a `guard` call by its `when` statement |
| Target | Selection of `guard` call |
| Inverse of | [Extract guard](#guard-extract-guard) |
| Notes | 1. `guard` must be defined on the same module <br> 2. `guard` definition will not be removed |
| Example | ![Example](assets/examples/guard/inline_guard.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Guard: rename guard

| | |
|-|-|
| Description | Replace the name of `guard` in all its calls |
| Target | Cursor at `guard` definition or usage |
| Read more | [Catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings?tab=readme-ov-file#rename-an-identifier) |
| Notes | ⚠️ Renaming a public `guard` only affects the current file |
| Example | ![Example](assets/examples/guard/rename_guard.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### If else: use keyword syntax

| | |
|-|-|
| Description | Rewrite the `if else` using keyword syntax |
| Target | Line of `if` using regular syntax |
| Inverse of | [Use regular syntax](#if-else-use-regular-syntax) |
| Notes | Clauses must have a single statement |
| Example | ![Example](assets/examples/if_else/use_keyword_syntax.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### If else: use regular syntax

| | |
|-|-|
| Description | Rewrite the `if else` using regular syntax |
| Target | Line of `if` using keyword syntax |
| Inverse of | [Use keyword syntax](#if-else-use-keyword-syntax) |
| Example | ![Example](assets/examples/if_else/use_regular_syntax.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Pipeline: introduce IO.inspect

| | |
|-|-|
| Description | Pipe a piece of code into an `IO.inspect` |
| Target | Selection of any code |
| Inverse of | [Remove IO.inspect](#pipeline-remove-ioinspect) |
| Example | ![Example](assets/examples/pipeline/introduce_io_inspect.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Pipeline: introduce pipe

| | |
|-|-|
| Description | Pipe the first arg into `function` call or `case` condition |
| Target | Line of `function` call or `case` condition |
| Inverse of | [Remove pipe](#pipeline-remove-pipe) |
| Example | ![Example](assets/examples/pipeline/introduce_pipe.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Pipeline: remove IO.inspect

| | |
|-|-|
| Description | Remove `IO.inspect` call |
| Target | Line of `IO.inspect` call |
| Inverse of | [Introduce IO.inspect](#pipeline-introduce-ioinspect) |
| Example | ![Example](assets/examples/pipeline/remove_io_inspect.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Pipeline: remove pipe

| | |
|-|-|
| Description | Remove `\|>` from `function` call or `case` condition |
| Target | Line of pipe (`\|>`)  |
| Inverse of | [Introduce pipe](#pipeline-introduce-pipe) |
| Read more | [Catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings?tab=readme-ov-file#remove-single-pipe) |
| Example | ![Example](assets/examples/pipeline/remove_pipe.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Variable: extract variable

| | |
|-|-|
| Description | Extract a piece of code into a `variable` |
| Target | Selection of any code |
| Inverse of | [Inline variable](#variable-inline-variable) |
| Read more | [Catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings?tab=readme-ov-file#extract-expressions) |
| Example | ![Example](assets/examples/variable/extract_variable.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Variable: inline variable

| | |
|-|-|
| Description | Replace __all__ usages of `variable` by its value |
| Target | Selection of `variable` assignment |
| Inverse of | [Extract variable](#variable-extract-variable) |
| Read more | [Catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings?tab=readme-ov-file#temporary-variable-elimination) |
| Example | ![Example](assets/examples/variable/inline_variable.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Variable: rename variable

| | |
|-|-|
| Description | Replace the name of `variable` in all its usages  |
| Target | Cursor at `variable` definition |
| Read more | [Catalog of Elixir refactorings](https://github.com/lucasvegi/Elixir-Refactorings?tab=readme-ov-file#rename-an-identifier) |
| Example | ![Example](assets/examples/variable/rename_variable.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

<!-- vim: set tw=0: -->
