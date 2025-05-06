defmodule MainAppWeb.ApplicationSessionController do
  alias MainApp.Accounts
  use MainAppWeb, :controller

  def set_application(
        conn,
        %{"application" => %{"id" => application_id}} = _
      ) do
    application = Accounts.get_application!(conn.assigns.current_scope.user, application_id)

    conn
    |> put_flash(:info, "Application #{application.name} selected")
    |> MainAppWeb.Application.put_application_in_session(application)
    |> redirect(to: ~p"/applications")
  end
end
