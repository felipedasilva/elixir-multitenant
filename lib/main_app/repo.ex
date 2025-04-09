defmodule MainApp.Repo do
  use Ecto.Repo,
    otp_app: :main_app,
    adapter: Ecto.Adapters.Postgres
end
