defmodule MainAppWeb.ProductLive.Show do
  use MainAppWeb, :live_view

  alias MainApp.Inventories

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Product {@product.id}
        <:subtitle>This is a product record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/products"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/products/#{@product}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit product
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Sku">{@product.sku}</:item>
        <:item title="Name">{@product.name}</:item>
        <:item title="Description">{@product.description}</:item>
      </.list>

      <.table id="versions" rows={@versions}>
        <:col :let={version} label="ID">
          {version.id}
        </:col>
        <:col :let={version} label="Event">
          {version.event}
        </:col>
        <:col :let={version} label="Changes">
          {version.item_changes
          |> Enum.map(fn {name, _} -> name end)
          |> Enum.join(", ")}
        </:col>
        <:col :let={version} label="Inserted at">
          <span
            id={"version-insertedat-#{version.id}"}
            phx-hook="FormatDate"
            data-date={version.inserted_at}
          />
        </:col>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    # Inventories.subscribe_products(socket.assigns.current_scope)

    product = Inventories.get_product!(socket.assigns.current_scope, id)

    versions = Inventories.get_product_changes_by_id(socket.assigns.current_scope, id)

    {:ok,
     socket
     |> assign(:page_title, "Show Product")
     |> assign(:product, product)
     |> assign(:versions, versions)}
  end

  @impl true
  def handle_info(
        {:updated, %MainApp.Inventories.Product{id: id} = product},
        %{assigns: %{product: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :product, product)}
  end

  def handle_info(
        {:deleted, %MainApp.Inventories.Product{id: id}},
        %{assigns: %{product: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current product was deleted.")
     |> push_navigate(to: ~p"/products")}
  end
end
