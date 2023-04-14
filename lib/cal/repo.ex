defmodule Cal.Repo do
  use Ecto.Repo,
    otp_app: :cal,
    adapter: Ecto.Adapters.Postgres
end
