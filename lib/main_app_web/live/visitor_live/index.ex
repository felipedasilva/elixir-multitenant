defmodule MainAppWeb.VisitorsLive.Index do
  use MainAppWeb, :live_view

  alias MainApp.Inventories

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} visitor_scope={@visitor_scope}>
      <.header>
        Listing Products
        <:actions>
          <.button variant="primary" navigate={~p"/products/new"}>
            <.icon name="hero-plus" /> New Product
          </.button>
        </:actions>
      </.header>

      <.form for={@form}>
        <Flop.Phoenix.filter_fields :let={i} form={@form} fields={[:search]}>
          <.input field={i.field} label={i.label} type={i.type} {i.rest} />
        </Flop.Phoenix.filter_fields>

        <.button variant="primary">
          Filter
        </.button>
      </.form>
      <Flop.Phoenix.table
        items={@streams.products}
        meta={@meta}
        path={~p"/products"}
        on_sort={JS.push("sort-products")}
        opts={[table_attrs: [class: "table"]]}
      >
        <:col :let={{_, product}} label="ID" field={:sku}>{product.id}</:col>
        <:col :let={{_, product}} label="Sku" field={:sku}>{product.sku}</:col>
        <:col :let={{_, product}} label="Name" field={:name}>{product.name}</:col>
        <:col :let={{_, product}} label="Source" field={:source}>{product.source}</:col>
        <:col :let={{_, product}} label="ExternalId" field={:external_id}>{product.external_id}</:col>
        <:col :let={{_, product}} label="Updated at" field={:updated_at}>
          <span
            id={"product-updatedat-#{product.id}"}
            phx-hook="FormatDate"
            data-date={product.updated_at}
          />
        </:col>
        <:action :let={{id, product}}>
          <.link class="btn btn-ghost btn-xs" navigate={~p"/products/#{product}"}>Show</.link>
          <.link class="btn btn-ghost btn-xs" navigate={~p"/products/#{product}/edit"}>Edit</.link>
          <.link
            class="btn btn-ghost btn-xs"
            phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </Flop.Phoenix.table>

      <.pagination meta={@meta} path={~p"/products"} />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    Inventories.subscribe_products(socket.assigns.visitor_scope)

    {
      :ok,
      socket
      |> assign(:page_title, "Listing Products")
      |> assign(:meta, %Flop.Meta{})
      |> assign(:flop, %Flop{})
      |> assign(:form, Phoenix.Component.to_form(%Flop.Meta{}))
      |> stream(:products, [])
    }
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Inventories.get_product!(socket.assigns.visitor_scope, id)

    {:ok, _} =
      Inventories.delete_product(socket.assigns.visitor_scope, product)

    {:noreply,
     socket
     |> put_flash(:info, "Product deleted successfully")
     |> stream_delete(:products, product)}
  end

  @impl true
  def handle_event("sort-products", %{"order" => order}, socket) do
    flop = Flop.push_order(socket.assigns.meta.flop, order)

    {:ok, {products, meta}} =
      Inventories.list_products(socket.assigns.visitor_scope, flop)

    {:noreply, socket |> assign(meta: meta) |> stream(:products, products)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    {:ok, {products, meta}} =
      Inventories.list_products(socket.assigns.visitor_scope, params)

    {:noreply,
     socket
     |> assign(meta: meta)
     |> assign(:form, Phoenix.Component.to_form(meta))
     |> stream(:products, products, reset: true)}
  end

  @impl true
  def handle_info({type, %MainApp.Inventories.Product{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:ok, {products, meta}} =
      Inventories.list_products(
        socket.assigns.visitor_scope,
        socket.assigns.meta.flop
      )

    {:noreply, socket |> assign(:meta, meta) |> stream(:products, products, reset: true)}
  end
end
