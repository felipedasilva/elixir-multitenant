defmodule MainApp.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `MainApp.Accounts` context.
  """

  import Ecto.Query

  alias MainApp.Accounts.Application
  alias MainApp.Accounts
  alias MainApp.Accounts.Scope

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        Accounts.deliver_login_instructions(user, url)
      end)

    {:ok, user, _expired_tokens} = Accounts.login_user_by_magic_link(token)

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def set_password(user) do
    {:ok, user, _expired_tokens} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_inserted_at(token, inserted_at) when is_binary(token) do
    MainApp.Repo.update_all(
      from(t in Accounts.UserToken,
        where: t.token == ^token
      ),
      set: [inserted_at: inserted_at]
    )
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    MainApp.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  def generate_default_application_fixture() do
    scope = user_scope_fixture(user_fixture(%{email: "admin@gmail"}))

    generate_default_application_fixture(scope)
  end

  def generate_default_application_fixture(scope) do
    {:ok, application} =
      Accounts.create_application(scope, %{name: "apptest", subdomain: "apptest"})

    application
  end

  def default_application_scope_fixture(scope) do
    application_default = MainApp.Repo.get_by!(Application, %{name: "myapp1"})

    Accounts.link_user_to_application(scope.user, application_default)

    Scope.put_application(scope, application_default)
  end

  def second_application_scope_fixture(scope) do
    application_second = MainApp.Repo.get_by!(Application, %{name: "myapp2"})

    Accounts.link_user_to_application(scope.user, application_second)

    Scope.put_application(scope, application_second)
  end
end
