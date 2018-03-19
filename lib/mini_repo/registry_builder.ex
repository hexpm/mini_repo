defmodule MiniRepo.RegistryBuilder do
  @repo "mini_repo"

  def build_names(packages) do
    packages =
      for {name, %{releases: _}} <- packages do
        %{name: name, repository: @repo}
      end

    encode(%{packages: packages}, &:hex_registry.encode_names/1)
  end

  def build_versions(packages) do
    packages =
      for {name, %{releases: releases}} <- packages do
        versions = for release <- releases, do: release.version
        package = %{name: name, versions: versions, repository: @repo}

        retired =
          for {release, index} <- Enum.with_index(releases),
              Map.has_key?(release, :retired),
              do: index

        if retired == [] do
          package
        else
          Map.put(package, :retired, retired)
        end
      end

    encode(%{packages: packages}, &:hex_registry.encode_versions/1)
  end

  def build_package(package) do
    encode(package, &:hex_registry.encode_package/1)
  end

  defp encode(payload, encoder) do
    private_key = Application.fetch_env!(:mini_repo, :private_key)

    payload
    |> encoder.()
    |> :hex_registry.sign_protobuf(private_key)
    |> :zlib.gzip()
  end
end

