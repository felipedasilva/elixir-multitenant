defmodule MainAppWeb.ApplicationLiveTest do
  use MainAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import MainApp.AccountsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_user

  defp create_application(%{scope: scope}) do
    application = generate_default_application_fixture(scope.user)

    %{application: application}
  end

  describe "Index" do
    setup [:create_application]

    test "lists all applications", %{conn: conn, application: application} do
      {:ok, _index_live, html} = live(conn, ~p"/applications")

      assert html =~ "Listing Applications"
      assert html =~ application.name
    end

    test "saves new application", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/applications")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Application")
               |> render_click()
               |> follow_redirect(conn, ~p"/applications/new")

      assert render(form_live) =~ "New Application"

      assert form_live
             |> form("#application-form", application: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#application-form", application: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/applications")

      html = render(index_live)
      assert html =~ "Application created successfully"
      assert html =~ "some name"
    end

    test "updates application in listing", %{conn: conn, application: application} do
      {:ok, index_live, _html} = live(conn, ~p"/applications")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#applications-#{application.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/applications/#{application}/edit")

      assert render(form_live) =~ "Edit Application"

      assert form_live
             |> form("#application-form", application: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#application-form", application: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/applications")

      html = render(index_live)
      assert html =~ "Application updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes application in listing", %{conn: conn, application: application} do
      {:ok, index_live, _html} = live(conn, ~p"/applications")

      assert index_live
             |> element("#applications-#{application.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#applications-#{application.id}")
    end

    # test "set application as current application", %{conn: conn, application: application} do
    #   {:ok, index_live, _html} = live(conn, ~p"/applications")

    #   assert index_live
    #          |> element("#applications-#{application.id} a", "Set")
    #          |> render_click() =~ "Application #{application.name} selected"
    # end
  end

  describe "Show" do
    setup [:create_application]

    test "displays application", %{conn: conn, application: application} do
      {:ok, _show_live, html} = live(conn, ~p"/applications/#{application}")

      assert html =~ "Show Application"
      assert html =~ application.name
    end

    test "updates application and returns to show", %{conn: conn, application: application} do
      {:ok, show_live, _html} = live(conn, ~p"/applications/#{application}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/applications/#{application}/edit?return_to=show")

      assert render(form_live) =~ "Edit Application"

      assert form_live
             |> form("#application-form", application: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#application-form", application: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/applications/#{application}")

      html = render(show_live)
      assert html =~ "Application updated successfully"
      assert html =~ "some updated name"
    end
  end
end
