defmodule TeckFanzine.Repo do
  use Ecto.Repo,
    otp_app: :teck_fanzine,
    adapter: Ecto.Adapters.SQLite3
end
