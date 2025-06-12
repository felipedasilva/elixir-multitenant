defmodule MainAppWeb.VisitorLiveTest do
  alias MainApp.Accounts.Scope
  use MainAppWeb.ConnCase

  import MainApp.InventoriesFixtures
  import MainApp.AccountsFixtures
  import Phoenix.LiveViewTest

  defp setup_create_application_and_product(%{conn: conn}) do
    user = user_fixture()
    application = MainApp.Repo.get_by!(MainApp.Accounts.Application, %{name: "myapp1"})
    scope = Scope.for_user(user) |> Scope.put_application(application)

    MainApp.Accounts.link_user_to_application(user, application)
    {:ok, product} = create_product(scope)

    %{conn: conn, application: application, product: product}
  end

  describe "Visitor page" do
    setup :setup_create_application_and_product

    test "show products of application", %{product: product} do
      conn =
        Phoenix.ConnTest.build_conn()
        |> Map.put(:host, "myappone.localhost")

      {:ok, _index_live, html} = live(conn, ~p"/visitors")

      assert html =~ "Listing Products"
      assert html =~ product.sku
    end

    test "not show products from other applications" do
      user = user_fixture(email: "testtwo@gmail.com")
      second_application = MainApp.Repo.get_by!(MainApp.Accounts.Application, %{name: "myapp2"})
      scope = Scope.for_user(user) |> Scope.put_application(second_application)
      MainApp.Accounts.link_user_to_application(user, second_application)
      {:ok, product} = create_product(scope, %{sku: "secondsku"})

      conn =
        Phoenix.ConnTest.build_conn()
        |> Map.put(:host, "myappone.localhost")

      {:ok, _index_live, html} = live(conn, ~p"/visitors")

      assert html =~ "Listing Products"
      refute html =~ product.sku
    end
  end
end
