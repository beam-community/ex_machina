defmodule ExMachina.Mixfile do
  use Mix.Project

  @project_url "https://github.com/thoughtbot/ex_machina"
  @version "0.4.0"

  def project do
    [
      app: :ex_machina,
      version: @version,
      elixir: "~> 1.0",
      description: "Easily create test data for Elixir applications",
      source_url: @project_url,
      homepage_url: @project_url,
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      package: package,
      docs: [main: "README", extras: ["README.md"]],
      deps: deps
    ]
  end

  def application do
    [
      applications: app_list(Mix.env),
      mod: {ExMachina, []}
    ]
  end

  def app_list(:test), do: app_list ++ [:ecto, :sqlite_ecto]
  def app_list(_), do: app_list
  def app_list, do: [:logger]

  defp deps do
    [
      {:ex_doc, "~> 0.9", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ecto, "~> 1.0", only: :test},
      {:sqlite_ecto, "~> 1.0.0", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Josh Steiner", "Paul Smith"],
      licenses: ["MIT"],
      links: %{"GitHub" => @project_url}
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths ++ ["test/support"]
  defp elixirc_paths(_), do: elixirc_paths
  defp elixirc_paths, do: ["lib"]
end
