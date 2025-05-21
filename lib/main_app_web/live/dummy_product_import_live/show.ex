defmodule MainAppWeb.DummyProductImportLive.Show do
  use MainAppWeb, :live_view

  alias MainApp.ExternalInventories

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Dummy product import {@dummy_product_import.id}
        <:subtitle>This is a dummy_product_import record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/dummy_product_imports"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/dummy_product_imports/#{@dummy_product_import}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit dummy_product_import
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@dummy_product_import.name}</:item>
        <:item title="Url">{@dummy_product_import.url}</:item>
        <:item title="Description">{@dummy_product_import.description}</:item>
        <:item title="Job interval in seconds">{@dummy_product_import.job_interval_in_seconds}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    ExternalInventories.subscribe_dummy_product_imports(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Show Dummy product import")
     |> assign(:dummy_product_import, ExternalInventories.get_dummy_product_import!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %MainApp.ExternalInventories.DummyProductImport{id: id} = dummy_product_import},
        %{assigns: %{dummy_product_import: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :dummy_product_import, dummy_product_import)}
  end

  def handle_info(
        {:deleted, %MainApp.ExternalInventories.DummyProductImport{id: id}},
        %{assigns: %{dummy_product_import: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current dummy_product_import was deleted.")
     |> push_navigate(to: ~p"/dummy_product_imports")}
  end
end
