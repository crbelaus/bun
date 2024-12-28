defmodule Bun.MixProject do
  use Mix.Project

  @version "1.4.1"
  @source_url "https://github.com/crbelaus/bun"

  def project do
    [
      app: :bun,
      version: @version,
      elixir: "~> 1.15",
      deps: deps(),
      description: "Mix tasks for installing and invoking bun",
      package: [
        links: %{
          "GitHub" => @source_url,
          "bun" => "https://bun.sh"
        },
        licenses: ["MIT"]
      ],
      docs: [
        main: "Bun",
        source_url: @source_url,
        source_ref: "v#{@version}",
        extras: ["CHANGELOG.md"]
      ],
      aliases: [
        test: ["bun.install --if-missing", "test"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, inets: :optional, ssl: :optional],
      mod: {Bun, []},
      env: [default: []]
    ]
  end

  defp deps do
    [
      {:castore, ">= 0.0.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
