defmodule MainAppWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use MainAppWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint MainAppWeb.Endpoint

      use MainAppWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import MainAppWeb.ConnCase
    end
  end

  setup tags do
    MainApp.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn} = context) do
    user = MainApp.AccountsFixtures.user_fixture()
    scope = MainApp.Accounts.Scope.for_user(user)

    opts =
      context
      |> Map.take([:token_inserted_at])
      |> Enum.into([])

    %{conn: log_in_user(conn, user, opts), user: user, scope: scope}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user, opts \\ []) do
    token = MainApp.Accounts.generate_user_session_token(user)

    maybe_set_token_inserted_at(token, opts[:token_inserted_at])

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  defp maybe_set_token_inserted_at(_token, nil), do: nil

  defp maybe_set_token_inserted_at(token, inserted_at) do
    MainApp.AccountsFixtures.override_token_inserted_at(token, inserted_at)
  end

  def register_application(%{conn: conn, user: user, scope: scope}) do
    application = MainApp.Repo.get_by!(MainApp.Accounts.Application, %{name: "myapp1"})
    MainApp.Accounts.link_user_to_application(user, application)

    scope = MainApp.Accounts.Scope.put_application(scope, application)

    conn =
      conn
      |> Plug.Conn.put_session(:application, application)

    %{conn: conn, application: application, scope: scope}
  end
end
