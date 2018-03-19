defmodule MiniRepo.Endpoint do
  use Plug.Builder
  plug Plug.Logger, log: :debug
  plug MiniRepo.Router

  def child_spec(opts) do
    Plug.Adapters.Cowboy.child_spec(Keyword.merge([plug: __MODULE__], opts))
  end
end
