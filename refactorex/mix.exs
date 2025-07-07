defmodule Refactorex.MixProject do
  use Mix.Project

  def project do
    [
      app: :refactorex,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp description(), do: "Elixir source code refactoring"

  def application do
    [
      extra_applications: [:logger],
      mod: {Refactorex.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps, do: [{:sourceror, "~> 1.7"}]

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/gp-pereira/refactorex"}
    ]
  end
end
