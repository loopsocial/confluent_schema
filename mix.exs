defmodule ConfluentSchema.MixProject do
  use Mix.Project

  def project do
    [
      app: :confluent_schema,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:confluent_schema_registry, "~> 0.1.1"},
      {:ex_json_schema, "~> 0.9.2"},
      {:jason, "~> 1.0"}
    ]
  end
end
