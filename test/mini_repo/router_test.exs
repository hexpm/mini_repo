defmodule MiniRepo.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias MiniRepo.Repository

  @opts MiniRepo.Router.init([])

  setup do
    :ok = Repository.clear()
    :ok
  end

  test "/names" do
    conn = get("/names")
    payload = protobuf_response(conn, 200)
    names = :hex_registry.decode_names(payload)
    assert %{packages: []} = names

    {:ok, _} = Repository.publish(read_fixture("foo-0.1.0/foo-0.1.0.tar"))

    conn = get("/names")
    payload = protobuf_response(conn, 200)
    names = :hex_registry.decode_names(payload)
    assert names == %{packages: [%{name: "foo", repository: "mini_repo"}]}
  end

  test "/versions" do
    {:ok, _} = Repository.publish(read_fixture("foo-0.1.0/foo-0.1.0.tar"))
    {:ok, _} = Repository.publish(read_fixture("foo-0.1.1/foo-0.1.1.tar"))
    :ok = Repository.retire("foo", "0.1.1", :RETIRED_SECURITY, "CVE-000")

    conn = get("/versions")
    payload = protobuf_response(conn, 200)
    versions = :hex_registry.decode_versions(payload)

    assert versions == %{
             packages: [
               %{
                 name: "foo",
                 versions: ["0.1.0", "0.1.1"],
                 retired: [1],
                 repository: "mini_repo"
               }
             ]
           }
  end

  test "/packages/:name" do
    {:ok, %{checksum: checksum1}} = Repository.publish(read_fixture("foo-0.1.0/foo-0.1.0.tar"))
    {:ok, %{checksum: checksum2}} = Repository.publish(read_fixture("foo-0.1.1/foo-0.1.1.tar"))
    :ok = Repository.retire("foo", "0.1.1", :RETIRED_SECURITY, "CVE-000")

    conn = get("/packages/foo")
    payload = protobuf_response(conn, 200)
    package = :hex_registry.decode_package(payload)

    assert package == %{
             releases: [
               %{version: "0.1.0", checksum: checksum1, dependencies: []},
               %{
                 version: "0.1.1",
                 checksum: checksum2,
                 dependencies: [],
                 retired: %{message: "CVE-000", reason: :RETIRED_SECURITY}
               }
             ]
           }

    conn = get("/packages/bar")
    assert conn.status == 404
  end

  test "/tarballs/:name_version.tar" do
    {:ok, _} = Repository.publish(read_fixture("foo-0.1.0/foo-0.1.0.tar"))

    conn = get("/tarballs/foo-0.1.0.tar")
    assert conn.status == 200
    assert conn.resp_body == read_fixture("foo-0.1.0/foo-0.1.0.tar")
  end

  defp get(path) do
    conn = conn(:get, path)
    MiniRepo.Router.call(conn, @opts)
  end

  defp read_fixture(path) do
    Path.join(["test", "fixtures", path]) |> File.read!()
  end

  defp protobuf_response(conn, status) do
    assert conn.status == status

    %{payload: payload} =
      conn.resp_body
      |> :zlib.gunzip()
      |> :hex_registry.decode_signed()

    payload
  end
end
