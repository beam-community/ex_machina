defmodule ExMachina.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_machina,
      description: "A factory library by the creators of FactoryBot (née FactoryGirl)",
      version: "2.8.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      source_url: "https://github.com/beam-community/ex_machina",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.circle": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExMachina, []}
    ]
  end

  defp deps do
    [
      {:ecto, "~> 2.2 or ~> 3.0", optional: true},
      {:ecto_sql, "~> 3.0", optional: true},

      # Dev and Test dependencies
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.21.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.17.1", only: :test},
      {:ex_doc, "~> 0.32", only: [:dev, :test], runtime: false},
      {:postgrex, "~> 0.17", only: :test}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md", "LICENSE.md"],
      main: "readme"
    ]
  end

  defp package do
    [
      maintainers: ["BEAM Community"],
      files: ~w(lib mix.exs .formatter.exs README.md CHANGELOG.md LICENSE.md),
      licenses: ["MIT"],
      links: %{
        Changelog: "https://github.com/beam-community/ex_machina/releases",
        GitHub: "https://github.com/beam-community/ex_machina"
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
