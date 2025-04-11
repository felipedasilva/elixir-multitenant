defmodule MainApp.Accounts.Application do
  @moduledoc """
  Define the application to work with, an account can have many applications.
  """
  use Ecto.Schema

  import Ecto.Changeset

  schema "applications" do
    field :tenant, :string
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(application, params \\ %{}) do
    application
    |> cast(params, [:name])
    |> validate_required([:name])
    |> unique_tenant()
  end

  defp unique_tenant(changeset) do
    case get_field(changeset, :tenant) do
      nil ->
        unique_tenant =
          changeset
          |> get_field(:name)
          |> Kernel.||("")
          |> String.downcase()
          |> Kernel.<>(System.unique_integer() |> Integer.to_string())
          |> String.replace(" ", "_")
          |> String.replace("-", "_")

        changeset |> put_change(:tenant, "tenant_" <> unique_tenant)

      _ ->
        changeset
    end
  end
end
