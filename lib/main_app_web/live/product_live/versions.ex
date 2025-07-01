defmodule MainAppWeb.ProductLive.Versions do
  use MainAppWeb, :live_view
  use Phoenix.Component
  alias MainApp.Inventories

  @impl true
  def render(assigns) do
    ~H"""
    <.table id="versions" rows={@versions}>
      <:col :let={version} label="AAA">
        {version.id}
      </:col>
    </.table>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    versions = Inventories.get_product_changes_by_id(socket.assigns.current_scope, id)

    {
      :ok,
      socket
      |> assign(:versions, versions)
    }
  end
end
