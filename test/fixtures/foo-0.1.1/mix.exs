defmodule Foo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :foo,
      version: "0.1.1",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        description: "Test",
        maintainers: ["Wojtek Mach"],
        licenses: ["MIT"],
        links: %{}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
