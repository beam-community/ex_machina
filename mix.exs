defmodule Anvil.Mixfile do
  use Mix.Project

  def project do
    [
      app: :anvil,
      version: "0.0.1",
      elixir: "~> 1.0",
      source_url: "https://github.com/thoughtbot/anvil",
      homepage_url: "https://github.com/thoughtbot/anvil",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      docs: [extras: ["README.md"]],
      deps: deps
    ]
  end

  def application do
    [
      applications: [:logger],
      mod: {Anvil, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.9", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev}
    ]
  end
end
