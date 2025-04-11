defmodule MainApp.Accounts.ApplicationUser do
  @moduledoc """
  Define the application to work with, an account can have many applications.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "application_users" do
    belongs_to :application, MainApp.Accounts.Application
    belongs_to :user, MainApp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(application_user, attrs) do
    application_user
    |> cast(attrs, [:user_id, :application_id])
    |> validate_required([:user_id, :application_id])
    |> unique_constraint([:user_id, :application_id], name: :unique_application_user)
  end
end
