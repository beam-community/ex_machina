defmodule ExMachina.Mixfile do
  use Mix.Project

  @project_url "https://github.com/thoughtbot/ex_machina"
  @version "2.2.0"

  def project() do
    [
      app: :ex_machina,
      version: @version,
      elixir: "~> 1.2",
      description: "A factory library by the creators of FactoryGirl",
      source_url: @project_url,
      homepage_url: @project_url,
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      package: package(),
      docs: [main: "readme", extras: ["README.md"]],
      deps: deps()
    ]
  end

  def application() do
    [
      applications: app_list(Mix.env),
      mod: {ExMachina, []}
    ]
  end

  def app_list(:test), do: app_list() ++ [:ecto, :postgrex]
  def app_list(_), do: app_list()
  def app_list(), do: [:logger]

  defp deps() do
    [
      {:ex_doc, "~> 0.14", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ecto, "~> 2.1", optional: true},
      {:postgrex, ">= 0.0.0", only: [:test]},
      {:poison, "~> 3.0", only: :test}
    ]
  end

  defp package() do
    [
      maintainers: ["Josh Steiner", "Paul Smith"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @project_url,
        "Made by thoughtbot" => "https://thoughtbot.com/services/elixir-phoenix",
      }
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths() ++ ["test/support"]
  defp elixirc_paths(_), do: elixirc_paths()
  defp elixirc_paths(), do: ["lib"]
end
