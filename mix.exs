defmodule RamlParser.Mixfile do
  use Mix.Project

  def project do
    [app: :raml_parser,
     version: "0.0.1",
     name: "Raml Parser",
     source_url: "https://github.com/natchapman/raml_parser",
     homepage_url: "https://github.com/natchapman/raml_parser",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     aliases: aliases,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test,
                         "coveralls.detail": :test,
                         "coveralls.post": :test,
                         "credo": :test,
                         "dialyze": :test,
                         "docs": :docs,
                         "inch": :test]
    ]
  end

  def application do
    [
      applications: [
        :logger,
        :yamerl
      ]
    ]
  end

  defp deps do
    [
      {:yamerl, github: "yakaz/yamerl"},
      {:ex_spec, "~> 1.0.0", only: :test},
      {:credo, "~> 0.3", only: :test},
      {:inch_ex, "> 0.0.0", only: [:test, :docs]},
      {:earmark, "~> 0.1", only: :docs},
      {:ex_doc, "~> 0.11", only: :docs},
      {:dialyze, "~> 0.2.0", only: :test},
      {:excoveralls, "~> 0.4", only: :test}
    ]
  end

  defp aliases do
    [test: ["coveralls", "inch", "credo", "dialyze"],
     docs: ["inch", "docs"]]
  end
end
