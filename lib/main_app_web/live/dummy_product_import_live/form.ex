defmodule MainAppWeb.DummyProductImportLive.Form do
  use MainAppWeb, :live_view

  alias MainApp.ExternalInventories
  alias MainApp.ExternalInventories.DummyProductImport

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage dummy_product_import records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="dummy_product_import-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:url]} type="text" label="Url" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:job_interval_in_seconds]} type="text" label="Job interval in seconds" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Dummy product import</.button>
          <.button navigate={return_path(@current_scope, @return_to, @dummy_product_import)}>
            Cancel
          </.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    dummy_product_import =
      ExternalInventories.get_dummy_product_import!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Dummy product import")
    |> assign(:dummy_product_import, dummy_product_import)
    |> assign(
      :form,
      to_form(
        ExternalInventories.change_dummy_product_import(
          socket.assigns.current_scope,
          dummy_product_import
        )
      )
    )
  end

  defp apply_action(socket, :new, _params) do
    dummy_product_import = %DummyProductImport{}

    socket
    |> assign(:page_title, "New Dummy product import")
    |> assign(:dummy_product_import, dummy_product_import)
    |> assign(
      :form,
      to_form(
        ExternalInventories.change_dummy_product_import(
          socket.assigns.current_scope,
          dummy_product_import
        )
      )
    )
  end

  @impl true
  def handle_event("validate", %{"dummy_product_import" => dummy_product_import_params}, socket) do
    changeset =
      ExternalInventories.change_dummy_product_import(
        socket.assigns.current_scope,
        socket.assigns.dummy_product_import,
        dummy_product_import_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"dummy_product_import" => dummy_product_import_params}, socket) do
    save_dummy_product_import(socket, socket.assigns.live_action, dummy_product_import_params)
  end

  defp save_dummy_product_import(socket, :edit, dummy_product_import_params) do
    case ExternalInventories.update_dummy_product_import(
           socket.assigns.current_scope,
           socket.assigns.dummy_product_import,
           dummy_product_import_params
         ) do
      {:ok, dummy_product_import} ->
        {:noreply,
         socket
         |> put_flash(:info, "Dummy product import updated successfully")
         |> push_navigate(
           to:
             return_path(
               socket.assigns.current_scope,
               socket.assigns.return_to,
               dummy_product_import
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_dummy_product_import(socket, :new, dummy_product_import_params) do
    case ExternalInventories.create_dummy_product_import(
           socket.assigns.current_scope,
           dummy_product_import_params
         ) do
      {:ok, dummy_product_import} ->
        {:noreply,
         socket
         |> put_flash(:info, "Dummy product import created successfully")
         |> push_navigate(
           to:
             return_path(
               socket.assigns.current_scope,
               socket.assigns.return_to,
               dummy_product_import
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _dummy_product_import), do: ~p"/dummy_product_imports"

  defp return_path(_scope, "show", dummy_product_import),
    do: ~p"/dummy_product_imports/#{dummy_product_import}"
end
