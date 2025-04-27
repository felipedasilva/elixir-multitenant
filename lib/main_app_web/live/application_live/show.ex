defmodule MainAppWeb.ApplicationLive.Show do
  use MainAppWeb, :live_view

  alias MainApp.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Application {@application.id}
        <:subtitle>This is a application record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/applications"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/applications/#{@application}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit application
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@application.name}</:item>
        <:item title="Tenant">{@application.tenant}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Application")
     |> assign(:application, Accounts.get_application!(socket.assigns.current_scope.user, id))}
  end

  @impl true
  def handle_info(
        {:updated, %MainApp.Accounts.Application{id: id} = application},
        %{assigns: %{application: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :application, application)}
  end

  def handle_info(
        {:deleted, %MainApp.Accounts.Application{id: id}},
        %{assigns: %{application: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current application was deleted.")
     |> push_navigate(to: ~p"/applications")}
  end
end
