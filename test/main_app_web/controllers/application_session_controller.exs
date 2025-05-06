defmodule MainAppWeb.ApplicationSessionControllerTest do
  use MainAppWeb.ConnCase, async: true

  setup do
    user = user_fixture()
    application = generate_default_application_fixture(user)
    %{user: user, application: application}
  end

  describe "POST /users/set-application" do
    test "set application", %{conn: conn, user: user, application: application} do
      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/users/set-application", %{
          %{"application" => %{"id" => application.id}}
        })

      refute get_session(conn, :application)
    end
  end
end
