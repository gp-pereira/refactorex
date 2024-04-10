defmodule Refactorex.Refactoring do
  defstruct [
    # This will be the Refactor responsible for the refactoring
    :module,
    # This will be the code action name that appears to the user
    :title,
    # This will be used to group same category refactors on menus
    # - quickfix
    # - refactor
    # - refactor.extract
    # - refactor.inline
    # - refactor.rewrite
    # - source
    # - source.organizeImports
    :kind,
    # This will contain the changes required to perform the
    # refactoring. Each diff carries some new text and its range
    :diffs
  ]
end
