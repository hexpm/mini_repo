defmodule MiniRepo.Router do
  @moduledoc false
  use Plug.Router
  alias MiniRepo.{Repository, RegistryBuilder}

  plug :match
  plug :dispatch

  get "/public_key" do
    conn
    |> put_resp_header("content-type", "application/x-pem-file")
    |> send_resp(200, Application.fetch_env!(:mini_repo, :public_key))
  end

  get "/names" do
    send_resp(conn, 200, RegistryBuilder.build_names(Repository.packages()))
  end

  get "/versions" do
    send_resp(conn, 200, RegistryBuilder.build_versions(Repository.packages()))
  end

  get "/packages/:name" do
    case Repository.fetch(name) do
      {:ok, package} ->
        send_resp(conn, 200, RegistryBuilder.build_package(package))

      :error ->
        send_resp(conn, 404, "not found")
    end
  end

  get "/tarballs/:name_version_tar" do
    path = Path.join(Repository.tarballs_dir(), name_version_tar)
    send_file(conn, 200, path)
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
