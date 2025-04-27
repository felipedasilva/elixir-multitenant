defmodule MainAppWeb.ApplicationLive.Index do
  use MainAppWeb, :live_view

  alias MainApp.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Applications
        <:actions>
          <.button variant="primary" navigate={~p"/applications/new"}>
            <.icon name="hero-plus" /> New Application
          </.button>
        </:actions>
      </.header>

      <.table
        id="applications"
        rows={@streams.applications}
        row_click={fn {_id, application} -> JS.navigate(~p"/applications/#{application}") end}
      >
        <:col :let={{_id, application}} label="Name">{application.name}</:col>
        <:col :let={{_id, application}} label="Tenant">{application.tenant}</:col>
        <:action :let={{_id, application}}>
          <div class="sr-only">
            <.link navigate={~p"/applications/#{application}"}>Show</.link>
          </div>
          <.link navigate={~p"/applications/#{application}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, application}}>
          <.link
            phx-click={JS.push("delete", value: %{id: application.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Applications")
     |> stream(:applications, Accounts.list_applications(socket.assigns.current_scope.user))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    application = Accounts.get_application!(socket.assigns.current_scope.user, id)
    {:ok, _} = Accounts.delete_application(socket.assigns.current_scope.user, application)

    {:noreply, stream_delete(socket, :applications, application)}
  end

  @impl true
  def handle_info({type, %MainApp.Accounts.Application{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(socket, :applications, Accounts.list_applications(socket.assigns.current_scope.user),
       reset: true
     )}
  end
end
