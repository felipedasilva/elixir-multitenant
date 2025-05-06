defmodule MainAppWeb.Application do
  alias MainApp.Accounts.Scope
  use MainAppWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  def on_mount(:mount_current_scope, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    {:cont, socket}
  end

  def on_mount(:require_application, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if socket.assigns.current_scope && socket.assigns.current_scope.application do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(
          :error,
          "You must select an application to access this page."
        )
        |> Phoenix.LiveView.redirect(to: ~p"/applications")

      {:halt, socket}
    end
  end

  defp mount_current_scope(socket, session) do
    current_scope = socket.assigns.current_scope

    current_scope =
      if application = session["application"] do
        Scope.put_application(current_scope, application)
      else
        current_scope
      end

    Phoenix.Component.assign(socket, :current_scope, current_scope)
  end

  def assign_application_to_scope(conn, _opts) do
    current_scope = conn.assigns.current_scope

    application = conn |> get_session(:application)

    IO.inspect(application, label: "assign_application_to_scope")

    if application do
      assign(
        conn,
        :current_scope,
        MainApp.Accounts.Scope.put_application(current_scope, application)
      )
    else
      conn
    end
  end

  def put_application_in_session(conn, application) do
    conn |> put_session(:application, application)
  end

  def require_application(conn, _opts) do
    if conn.assigns.current_scope && conn.assigns.current_scope.application do
      conn
    else
      conn
      |> put_flash(:error, "You must select an application to access this page.")
      |> redirect(~p"/applications")
      |> halt()
    end
  end
end
