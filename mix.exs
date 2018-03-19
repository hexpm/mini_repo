defmodule MiniRepo.MixProject do
  use Mix.Project

  def project() do
    [
      app: :mini_repo,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application() do
    [
      extra_applications: [:logger],
      mod: {MiniRepo.Application, []}
    ]
  end

  defp deps() do
    [
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.0"},
      {:hex_erl, github: "hexpm/hex_erl"}
    ]
  end

  defp aliases() do
    [
      server: &server/1
    ]
  end

  defp server(_) do
    Application.put_env(:mini_repo, :start_endpoint, true)
    Mix.Task.run("app.start")
  end
end
