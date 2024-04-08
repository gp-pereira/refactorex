defmodule Refactorex.MixProject do
  use Mix.Project

  def project do
    [
      app: :refactorex,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Refactorex.Application, []}
    ]
  end

  defp deps do
    [
      {:gen_lsp, "~> 0.3.0"},
      {:sourceror, "~> 1.0"},
      # {:diffie, "~> 0.2.0"},
      {:credo, "~> 1.7.0", only: [:test, :dev], runtime: false}
    ]
  end
end
