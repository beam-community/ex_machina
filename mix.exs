defmodule ExMachina.Mixfile do
  use Mix.Project

  @project_url "https://github.com/thoughtbot/ex_machina"
  @version "0.2.0"

  def project do
    [
      app: :ex_machina,
      version: @version,
      elixir: "~> 1.0",
      description: "Easily create test data for Elixir applications",
      source_url: @project_url,
      homepage_url: @project_url,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      package: package,
      docs: [main: "README", extras: ["README.md"]],
      deps: deps
    ]
  end

  def application do
    [
      applications: [:logger],
      mod: {ExMachina, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.9", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ecto, "~> 1.0", only: :test}
    ]
  end

  defp package do
    [
      contributors: ["Josh Steiner", "Paul Smith"],
      licenses: ["MIT"],
      links: %{"GitHub" => @project_url}
    ]
  end
end
