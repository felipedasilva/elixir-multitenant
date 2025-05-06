defmodule MainAppWeb.ApplicationLive.Index do
  use MainAppWeb, :live_view

  alias MainApp.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <%= if @current_scope && @current_scope.application do %>
        <h1>APP1: {@current_scope.application.name}</h1>
      <% end %>
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
          <.link phx-click={JS.push("set-current-application", value: %{id: application.id})}>
            Set
          </.link>
        </:action>
      </.table>
      <.form
        :let={f}
        id={"application-set-current-#{@trigger_submit_id}"}
        for={to_form(%{"id" => @trigger_submit_id}, as: "application")}
        action={~p"/users/set-application"}
        phx-submit="set-current-application"
        phx-trigger-action={@trigger_submit_id != nil}
        class="w-0 h-0 hidden"
      >
        <.input field={f[:id]} value={@trigger_submit_id} type="hidden" required />
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:trigger_submit_id, nil)
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
  def handle_event(
        "set-current-application",
        %{"id" => application_id},
        socket
      ) do
    {:noreply, assign(socket, trigger_submit_id: application_id)}
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
