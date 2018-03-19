defmodule MiniRepo.Repository do
  alias MiniRepo.Repository.State

  @name __MODULE__

  def child_spec(opts) do
    default = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }

    Supervisor.child_spec(default, opts)
  end

  def start_link() do
    File.mkdir_p!(tarballs_dir())
    Agent.start_link(fn -> State.load() end, name: @name)
  end

  def tarballs_dir() do
    data_dir = Application.fetch_env!(:mini_repo, :data_dir)
    Path.join([data_dir, "tarballs"])
  end

  def tarball_path(name, version) do
    Path.join([tarballs_dir(), "#{name}-#{version}.tar"])
  end

  def clear() do
    Agent.update(@name, fn _ -> %{} end)
  end

  def packages() do
    Agent.get(@name, & &1)
  end

  def fetch(name) do
    Agent.get(@name, &Map.fetch(&1, name))
  end

  def publish(tarball) when is_binary(tarball) do
    {:ok, package} = :hex_tarball.unpack(tarball, :memory)
    name = package.metadata["name"]
    version = package.metadata["version"]
    File.write!(tarball_path(name, version), tarball)
    release = build_release(package)

    :ok =
      Agent.update(@name, fn state ->
        state
        |> publish(name, release)
        |> State.dump()
      end)

    {:ok, package}
  end

  def retire(name, version, reason, message) do
    Agent.update(@name, fn state ->
      state
      |> retire(name, version, reason, message)
      |> State.dump()
    end)
  end

  defp publish(state, name, release) do
    Map.update(state, name, %{releases: [release]}, &add_release(name, &1, release))
  end

  defp build_release(package) do
    version = package.metadata["version"]
    dependencies = build_dependencies(package.metadata["requirements"])
    %{version: version, checksum: package.checksum, dependencies: dependencies}
  end

  defp add_release(package_name, package, release) do
    if (release.version in Enum.map(package.releases, & &1.version)) do
      raise "#{package_name} #{release.version} already published"
    else
      %{package | releases: package.releases ++ [release]}
    end
  end

  defp build_dependencies(requirements) do
    Enum.map(requirements, fn {package, map} ->
      %{
        package: package,
        requirement: map["requirement"]
      }
      |> maybe_put(:app, map["app"])
      |> maybe_put(:optional, map["optional"])
      |> maybe_put(:repository, map["repository"])
    end)
  end

  def retire(state, name, version, reason, message) do
    Map.update!(state, name, &do_retire(&1, version, reason, message))
  end

  defp do_retire(package, version, reason, message) do
    true = version in Enum.map(package.releases, & &1.version)

    releases =
      Enum.map(package.releases, fn release ->
        if release.version == version do
          Map.put(release, :retired, %{reason: reason, message: message})
        else
          release
        end
      end)

    %{package | releases: releases}
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end

defmodule MiniRepo.Repository.State do
  @moduledoc false

  def path() do
    data_dir = Application.fetch_env!(:mini_repo, :data_dir)
    Path.join([data_dir, "state.bin"])
  end

  def load() do
    case File.read(path()) do
      {:ok, binary} -> :erlang.binary_to_term(binary)
      {:error, :enoent} -> %{}
    end
  end

  def dump(state) do
    File.write!(path(), :erlang.term_to_binary(state))
    state
  end
end
