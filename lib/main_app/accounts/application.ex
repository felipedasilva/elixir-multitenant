defmodule MainApp.Accounts.Application do
  @moduledoc """
  Define the application to work with, an account can have many applications.
  """
  @derive {Jason.Encoder, only: [:id, :name, :tenant]}

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  schema "applications" do
    field :tenant, :string
    field :subdomain, :string
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(application, params \\ %{}) do
    application
    |> cast(params, [:name, :subdomain])
    |> validate_required([:name, :subdomain])
    |> validate_format(:subdomain, ~r/^[a-z]+$/, message: "must have only letters")
    |> validate_subdomain()
    |> unique_constraint(:subdomain)
    |> unique_tenant()
  end

  def validate_subdomain(changeset) do
    case fetch_change(changeset, :subdomain) do
      {:ok, subdomain} ->
        exists? =
          MainApp.Repo.exists?(
            from a in MainApp.Accounts.Application, where: a.subdomain == ^subdomain
          )

        if exists? do
          add_error(changeset, :subdomain, "has already been taken")
        else
          changeset
        end

      :error ->
        changeset
    end
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
