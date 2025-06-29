defmodule RefactorexWorkspace.MixProject do
  use Mix.Project

  def project do
    [
      app: :refactorex_workspace,
      version: "0.1.0",
      elixir: "~> 1.13",
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application, do: [extra_applications: []]

  defp deps, do: [{:credo, "~> 1.7", only: [:dev, :test], runtime: false}]

  defp aliases do
    [
      "test.all": ["cmd --cd refactorex mix test", "cmd --cd refactorex_lsp mix test"],
      "deps.all": ["cmd --cd refactorex mix deps.get", "cmd --cd refactorex_lsp mix deps.get"],
      "credo.all": ["credo --config-file .credo.exs"],
      "check.all": ["format.all --check-formatted", "credo.all --strict", "test.all"]
    ]
  end
end
