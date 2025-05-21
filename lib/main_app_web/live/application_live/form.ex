defmodule MainAppWeb.ApplicationLive.Form do
  use MainAppWeb, :live_view

  alias MainApp.Accounts
  alias MainApp.Accounts.Application

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage application records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="application-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Application</.button>
          <.button navigate={return_path(@current_scope, @return_to, @application)}>Cancel</.button>
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
    application = Accounts.get_application!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Application")
    |> assign(:application, application)
    |> assign(
      :form,
      to_form(Accounts.change_application(application))
    )
  end

  defp apply_action(socket, :new, _params) do
    # application = %Application{user_id: socket.assigns.current_scope.user.id}
    application = %Application{}

    socket
    |> assign(:page_title, "New Application")
    |> assign(:application, application)
    |> assign(
      :form,
      to_form(Accounts.change_application(application))
    )
  end

  @impl true
  def handle_event("validate", %{"application" => application_params}, socket) do
    changeset =
      Accounts.change_application(
        socket.assigns.application,
        application_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"application" => application_params}, socket) do
    save_application(socket, socket.assigns.live_action, application_params)
  end

  defp save_application(socket, :edit, application_params) do
    case Accounts.update_application(
           socket.assigns.current_scope,
           socket.assigns.application,
           application_params
         ) do
      {:ok, application} ->
        {:noreply,
         socket
         |> put_flash(:info, "Application updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, application)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_application(socket, :new, application_params) do
    case Accounts.create_application(socket.assigns.current_scope, application_params) do
      {:ok, application} ->
        {:noreply,
         socket
         |> put_flash(:info, "Application created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, application)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _application), do: ~p"/applications"
  defp return_path(_scope, "show", application), do: ~p"/applications/#{application}"
end
