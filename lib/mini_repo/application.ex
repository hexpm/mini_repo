defmodule MiniRepo.Application do
  @moduledoc false
  use Application
  require Logger

  def start(_type, _args) do
    children = [MiniRepo.Repository] ++ endpoint_children()
    Supervisor.start_link(children, [strategy: :one_for_one, name: MiniRepo.Supervisor])
  end

  defp endpoint_children() do
    if Application.get_env(:mini_repo, :start_endpoint, false) do
      opts = Application.fetch_env!(:mini_repo, MiniRepo.Endpoint)
      Logger.info("Starting #{inspect(MiniRepo.Endpoint)} on port #{opts[:options][:port]}")
      [{MiniRepo.Endpoint, opts}]
    else
      []
    end
  end
end
