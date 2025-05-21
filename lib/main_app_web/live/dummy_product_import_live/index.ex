defmodule MainAppWeb.DummyProductImportLive.Index do
  use MainAppWeb, :live_view

  alias MainApp.ExternalInventories

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Dummy product imports
        <:actions>
          <.button variant="primary" navigate={~p"/dummy_product_imports/new"}>
            <.icon name="hero-plus" /> New Dummy product import
          </.button>
        </:actions>
      </.header>

      <Flop.Phoenix.table
        id="dummy_product_imports"
        items={@streams.dummy_product_imports}
        meta={@meta}
        path={~p"/dummy_product_imports"}
        opts={[table_attrs: [class: "table"]]}
      >
        <:col :let={{_id, dummy_product_import}} label="Name">{dummy_product_import.name}</:col>
        <:col :let={{_id, dummy_product_import}} label="Url">{dummy_product_import.url}</:col>
        <:col :let={{_id, dummy_product_import}} label="Description">
          {dummy_product_import.description}
        </:col>
        <:col :let={{_id, dummy_product_import}} label="Job interval in seconds">
          {dummy_product_import.job_interval_in_seconds}
        </:col>
        <:action :let={{_id, dummy_product_import}}>
          <div class="sr-only">
            <.link navigate={~p"/dummy_product_imports/#{dummy_product_import}"}>Show</.link>
          </div>
          <.link navigate={~p"/dummy_product_imports/#{dummy_product_import}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, dummy_product_import}}>
          <.link
            phx-click={JS.push("delete", value: %{id: dummy_product_import.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </Flop.Phoenix.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    ExternalInventories.subscribe_dummy_product_imports(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:page_title, "Listing Dummy product imports")
     |> assign(:meta, %Flop.Meta{})
     |> assign(:flop, %Flop{})
     |> assign(:form, Phoenix.Component.to_form(%Flop.Meta{}))
     |> stream(:dummy_product_imports, [])}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    dummy_product_import =
      ExternalInventories.get_dummy_product_import!(socket.assigns.current_scope, id)

    {:ok, _} =
      ExternalInventories.delete_dummy_product_import(
        socket.assigns.current_scope,
        dummy_product_import
      )

    {:noreply, stream_delete(socket, :dummy_product_imports, dummy_product_import)}
  end

  @impl true
  def handle_event("sort", %{"order" => order}, socket) do
    flop = Flop.push_order(socket.assigns.meta.flop, order)

    {:ok, {dummy_product_imports, meta}} =
      ExternalInventories.list_dummy_product_imports(
        socket.assigns.current_scope,
        flop
      )

    {:noreply,
     socket |> assign(meta: meta) |> stream(:dummy_product_imports, dummy_product_imports)}
  end

  @impl true
  def handle_info({type, %MainApp.ExternalInventories.DummyProductImport{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:ok, {dummy_product_imports, meta}} =
      ExternalInventories.list_dummy_product_imports(
        socket.assigns.current_scope,
        socket.assigns.meta.flop
      )

    {:noreply,
     socket
     |> assign(:meta, meta)
     |> stream(
       :dummy_product_imports,
       dummy_product_imports,
       reset: true
     )}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _, socket) do
    {:ok, {dummy_product_imports, meta}} =
      ExternalInventories.list_dummy_product_imports(
        socket.assigns.current_scope,
        params
      )

    {:noreply,
     socket
     |> assign(meta: meta)
     |> assign(:form, Phoenix.Component.to_form(meta))
     |> stream(:dummy_product_imports, dummy_product_imports, reset: true)}
  end
end
