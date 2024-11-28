# Refactorex for VS Code

Uses the [Refactorex](https://github.com/gp-pereira/refactorex) language server to 
enhance VS Code with code actions to quickly refactor Elixir. 

![Example](https://github.com/gp-pereira/refactorex-vscode/blob/main/assets/examples/readme.gif?raw=true)

## Available refactorings

| Scope | Refactoring | Target | Published? |
| :-: | - | :-: | :-: |
| `alias` | [Expand aliases](#alias-expand-aliases) | selection | ✅ |
| `alias` | [Extract alias](#alias-extract-alias) | selection | ✅ |
| `alias` | [Inline alias](#alias-inline-alias) | selection | ✅ |
| `alias` | [Merge aliases](#alias-merge-aliases) | selection | ✅ |
| `alias` | [Sort nested aliases](#alias-sort-nested-aliases) | line | ✅ |
| | | |
| `constant` | [Extract constant](#constant-extract-constant) | selection | ✅ |
| `constant` | [Inline constant](#constant-inline-constant) | selection | ✅ |
| `constant` | [Rename constant](#constant-rename-constant) | selection | ✅ |
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
| `guard` | [Extract guard](#guard-extract-guard) | selection | ✅ |
| `guard` | [Inline guard](#guard-inline-guard) | selection | ✅ |
| `guard` | [Rename guard](#guard--guard) | selection | ✅ |
| | | |
| `if else` | [Use keyword syntax](#if-else-use-keyword-syntax) | line | ✅ |
| `if else` | [Use regular syntax](#if-else-use-regular-syntax) | line | ✅ |
| | | |
| `pipeline` | [Introduce IO.inspect](#pipeline-introduce-ioinspect) | selection | ✅ |
| `pipeline` | [Introduce pipe](#pipeline-introduce-pipe) | line |  ✅ |
| `pipeline` | [Remove IO.inspect](#pipeline-remove-ioinspect) | line | ✅ |
| `pipeline` | [Remove pipe](#pipeline-remove-pipe) | line | ✅ |
| | | |
| `variable` | [Extract variable](#variable-extract-variable) | selection | ✅ |
| `variable` | [Inline variable](#variable-inline-variable) | selection | ✅ |
| `variable` | [Rename variable](#variable-rename-variable) | selection | ✅ |

## How to use each refactoring

### Alias: expand aliases

| | |
|-|-|
| Description | Expand nested `aliases` to their full names |
| Target | Selection of nested `alias`, group of nested `aliases` or `alias` with nesting |
| Inverse of | [Merge aliases](#alias-merge-aliases) |
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
| Notes | Alias must be declared on the same module |
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
| Example | ![Example](assets/examples/constant/extract_constant.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Constant: inline constant

| | |
|-|-|
| Description | Replace a `constant` usage by its value |
| Target | Selection of `constant` |
| Inverse of | [Extract constant](#constant-extract-constant) |
| Example | ![Example](assets/examples/constant/inline_constant.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Constant: rename constant

| | |
|-|-|
| Description | Replace the name of `constant` in all its usages |
| Target | Selection of (or cursor over) `constant` |
| Example | ![Example](assets/examples/constant/rename_constant.gif?raw=true) |

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
| Notes | Guard must be defined on the same module |
| Example | ![Example](assets/examples/guard/inline_guard.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Guard: rename guard

| | |
|-|-|
| Description | Replace the name of `guard` in all its calls |
| Target | Selection of (or cursor over) `guard` name |
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
| Example | ![Example](assets/examples/pipeline/remove_pipe.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Variable: extract variable

| | |
|-|-|
| Description | Extract a piece of code into a `variable` |
| Target | Selection of any code |
| Inverse of | [Inline variable](#variable-inline-variable) |
| Example | ![Example](assets/examples/variable/extract_variable.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Variable: inline variable

| | |
|-|-|
| Description | Replace all usages of `variable` by its value |
| Target | Selection of `variable` declaration or assignment |
| Inverse of | [Extract variable](#variable-extract-variable) |
| Example | ![Example](assets/examples/variable/inline_variable.gif?raw=true) |

[▲ top](#available-refactorings)

<br>

### Variable: rename variable

| | |
|-|-|
| Description | Replace the name of `variable` in all its usages  |
| Target | Selection of (or cursor over) `variable` declaration or assignment |
| Example | ![Example](assets/examples/variable/rename_variable.gif?raw=true) |

[▲ top](#available-refactorings)

<br>



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

