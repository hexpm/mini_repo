use Mix.Config

config :logger, level: :info

config :mini_repo,
  data_dir: "tmp/data/#{Mix.env()}",
  private_key: File.read!(Path.join("priv", "test_priv.pem")),
  public_key: File.read!(Path.join("priv", "test_pub.pem"))

config :mini_repo, MiniRepo.Endpoint,
  scheme: :http,
  options: [
    port: String.to_integer(System.get_env("PORT") || "4000")
  ]
