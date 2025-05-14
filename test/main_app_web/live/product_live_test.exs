defmodule MainAppWeb.ProductLiveTest do
  use MainAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import MainApp.InventoriesFixtures
  import MainApp.AccountsFixtures

  @create_attrs %{name: "some name", description: "some description", slug: "some slug"}
  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    slug: "some updated slug"
  }
  @invalid_attrs %{name: nil, description: nil, slug: nil}

  setup :register_and_log_in_user

  defp setup_application_and_product(%{conn: conn}) do
    user = user_fixture()
    application = MainApp.Repo.get_by!(MainApp.Accounts.Application, %{name: "myapp1"})
    MainApp.Accounts.link_user_to_application(user, application)
    {:ok, product} = create_product(application.tenant)

    conn =
      conn
      |> log_in_user(user)
      |> Plug.Conn.put_session(:application, application)

    %{conn: conn, application: application, product: product}
  end

  describe "Index" do
    setup [:setup_application_and_product]

    test "lists all products", %{conn: conn, product: product} do
      {:ok, _index_live, html} = live(conn, ~p"/products")

      assert html =~ "Listing Products"
      assert html =~ product.slug
    end

    test "saves new product", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Product")
               |> render_click()
               |> follow_redirect(conn, ~p"/products/new")

      assert render(form_live) =~ "New Product"

      assert form_live
             |> form("#product-form", product: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#product-form", product: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/products")

      html = render(index_live)
      assert html =~ "Product created successfully"
      assert html =~ "some slug"
    end

    test "updates product in listing", %{conn: conn, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#products-#{product.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/products/#{product}/edit")

      assert render(form_live) =~ "Edit Product"

      assert form_live
             |> form("#product-form", product: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#product-form", product: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/products")

      html = render(index_live)
      assert html =~ "Product updated successfully"
      assert html =~ "some updated slug"
    end

    test "deletes product in listing", %{conn: conn, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/products")

      assert index_live |> element("#products-#{product.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#products-#{product.id}")
    end
  end

  describe "Show" do
    setup [:setup_application_and_product]

    test "displays product", %{conn: conn, product: product} do
      {:ok, _show_live, html} = live(conn, ~p"/products/#{product}")

      assert html =~ "Show Product"
      assert html =~ product.slug
    end

    test "updates product and returns to show", %{conn: conn, product: product} do
      {:ok, show_live, _html} = live(conn, ~p"/products/#{product}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/products/#{product}/edit?return_to=show")

      assert render(form_live) =~ "Edit Product"

      assert form_live
             |> form("#product-form", product: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#product-form", product: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/products/#{product}")

      html = render(show_live)
      assert html =~ "Product updated successfully"
      assert html =~ "some updated slug"
    end
  end
end
