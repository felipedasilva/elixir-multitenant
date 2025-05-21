defmodule MainAppWeb.DummyProductImportLiveTest do
  use MainAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import MainApp.ExternalInventoriesFixtures

  @create_attrs %{
    name: "some name",
    description: "some description",
    url: "some url",
    job_interval_in_seconds: "3600"
  }
  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    url: "some updated url",
    job_interval_in_seconds: "some updated job_interval_in_seconds"
  }
  @invalid_attrs %{name: nil, description: nil, url: nil, job_interval_in_seconds: nil}

  setup [:register_and_log_in_user, :register_application]

  defp create_dummy_product_import(%{scope: scope}) do
    dummy_product_import = dummy_product_import_fixture(scope)

    %{dummy_product_import: dummy_product_import}
  end

  describe "Index" do
    setup [:create_dummy_product_import]

    test "lists all dummy_product_imports", %{
      conn: conn,
      dummy_product_import: dummy_product_import
    } do
      {:ok, _index_live, html} = live(conn, ~p"/dummy_product_imports")

      assert html =~ "Listing Dummy product imports"
      assert html =~ dummy_product_import.name
    end

    test "saves new dummy_product_import", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/dummy_product_imports")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Dummy product import")
               |> render_click()
               |> follow_redirect(conn, ~p"/dummy_product_imports/new")

      assert render(form_live) =~ "New Dummy product import"

      assert form_live
             |> form("#dummy_product_import-form", dummy_product_import: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#dummy_product_import-form", dummy_product_import: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/dummy_product_imports")

      html = render(index_live)
      assert html =~ "Dummy product import created successfully"
      assert html =~ "some name"
    end

    test "updates dummy_product_import in listing", %{
      conn: conn,
      dummy_product_import: dummy_product_import
    } do
      {:ok, index_live, _html} = live(conn, ~p"/dummy_product_imports")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#dummy_product_imports-#{dummy_product_import.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/dummy_product_imports/#{dummy_product_import}/edit")

      assert render(form_live) =~ "Edit Dummy product import"

      assert form_live
             |> form("#dummy_product_import-form", dummy_product_import: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#dummy_product_import-form", dummy_product_import: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/dummy_product_imports")

      html = render(index_live)
      assert html =~ "Dummy product import updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes dummy_product_import in listing", %{
      conn: conn,
      dummy_product_import: dummy_product_import
    } do
      {:ok, index_live, _html} = live(conn, ~p"/dummy_product_imports")

      assert index_live
             |> element("#dummy_product_imports-#{dummy_product_import.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#dummy_product_imports-#{dummy_product_import.id}")
    end
  end

  describe "Show" do
    setup [:create_dummy_product_import]

    test "displays dummy_product_import", %{
      conn: conn,
      dummy_product_import: dummy_product_import
    } do
      {:ok, _show_live, html} = live(conn, ~p"/dummy_product_imports/#{dummy_product_import}")

      assert html =~ "Show Dummy product import"
      assert html =~ dummy_product_import.name
    end

    test "updates dummy_product_import and returns to show", %{
      conn: conn,
      dummy_product_import: dummy_product_import
    } do
      {:ok, show_live, _html} = live(conn, ~p"/dummy_product_imports/#{dummy_product_import}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(
                 conn,
                 ~p"/dummy_product_imports/#{dummy_product_import}/edit?return_to=show"
               )

      assert render(form_live) =~ "Edit Dummy product import"

      assert form_live
             |> form("#dummy_product_import-form", dummy_product_import: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#dummy_product_import-form", dummy_product_import: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/dummy_product_imports/#{dummy_product_import}")

      html = render(show_live)
      assert html =~ "Dummy product import updated successfully"
      assert html =~ "some updated name"
    end
  end
end
