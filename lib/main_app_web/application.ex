defmodule MainAppWeb.Application do
  alias MainApp.Accounts.Application
  alias MainApp.Accounts
  alias MainApp.Accounts.Scope
  use MainAppWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  def on_mount(:mount_current_scope, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    {:cont, socket}
  end

  def on_mount(:mount_visitor_scope, _params, session, socket) do
    socket = mount_visitor_scope(socket, session)

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

  def on_mount(:require_visitor_application, _params, session, socket) do
    socket = mount_visitor_scope(socket, session)

    if socket.assigns.visitor_scope && socket.assigns.visitor_scope.application do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(
          :error,
          "Application not found"
        )
        |> Phoenix.LiveView.redirect(to: ~p"/")

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

  defp mount_visitor_scope(socket, session) do
    visitor_scope = socket.assigns["visitor_scope"] || %Scope{}

    visitor_scope =
      if application = session["visitor_application"] do
        Scope.put_application(visitor_scope, application)
      else
        visitor_scope
      end

    Phoenix.Component.assign(socket, :visitor_scope, visitor_scope)
  end

  def assign_application_to_scope(conn, _opts) do
    application = conn |> get_session(:application)

    if application do
      current_scope = conn.assigns.current_scope

      assign(
        conn,
        :current_scope,
        MainApp.Accounts.Scope.put_application(current_scope, application)
      )
    else
      conn
    end
  end

  def assign_visitor_application_to_scope(conn, _opts) do
    visitor_application = conn |> get_session(:visitor_application)

    if visitor_application do
      visitor_scope = conn.assigns["visitor_scope"] || %Scope{}

      assign(
        conn,
        :visitor_scope,
        MainApp.Accounts.Scope.put_application(visitor_scope, visitor_application)
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

  def require_subdomain_application(conn, _opts) do
    parts = String.split(conn.host, ".")

    if Enum.count(parts) > 1 do
      subdomain = List.first(parts)

      case Accounts.get_application_by_subdomain(%Scope{}, subdomain) do
        %Application{} = application ->
          conn |> put_session(:visitor_application, application)

        _ ->
          conn
          |> put_flash(:error, "Application not found")
          |> redirect(~p"/")
          |> halt()
      end
    else
      conn
      |> put_flash(:error, "Application not found")
      |> redirect(~p"/")
      |> halt()
    end
  end
end
