defmodule MainApp.ExternalInventoriesTest do
  use MainApp.DataCase

  alias MainApp.ExternalInventories

  describe "dummy_product_imports" do
    alias MainApp.ExternalInventories.DummyProductImport

    import MainApp.AccountsFixtures

    import MainApp.ExternalInventoriesFixtures

    @invalid_attrs %{name: nil, description: nil, url: nil}

    test "list_dummy_product_imports/1 returns all scoped dummy_product_imports" do
      scope = user_scope_fixture() |> default_application_scope_fixture()
      other_scope = user_scope_fixture() |> second_application_scope_fixture()
      dummy_product_import = dummy_product_import_fixture(scope)
      other_dummy_product_import = dummy_product_import_fixture(other_scope)

      {:ok, {dummy_product_imports, _}} =
        ExternalInventories.list_dummy_product_imports(scope, %{})

      assert dummy_product_imports == [dummy_product_import]

      {:ok, {other_dummy_product_imports, _}} =
        ExternalInventories.list_dummy_product_imports(other_scope, %{})

      assert other_dummy_product_imports == [
               other_dummy_product_import
             ]
    end

    test "get_dummy_product_import!/2 returns the dummy_product_import with given id" do
      scope = user_scope_fixture() |> default_application_scope_fixture()
      dummy_product_import = dummy_product_import_fixture(scope)
      other_scope = user_scope_fixture() |> second_application_scope_fixture()

      assert ExternalInventories.get_dummy_product_import!(scope, dummy_product_import.id) ==
               dummy_product_import

      assert_raise Ecto.NoResultsError, fn ->
        ExternalInventories.get_dummy_product_import!(other_scope, dummy_product_import.id)
      end
    end

    test "create_dummy_product_import/2 with valid data creates a dummy_product_import" do
      valid_attrs = %{
        name: "some name",
        description: "some description",
        url: "some url",
        job_interval_in_seconds: "3600"
      }

      scope = user_scope_fixture() |> default_application_scope_fixture()

      assert {:ok, %DummyProductImport{} = dummy_product_import} =
               ExternalInventories.create_dummy_product_import(scope, valid_attrs)

      assert dummy_product_import.name == "some name"
      assert dummy_product_import.description == "some description"
      assert dummy_product_import.url == "some url"
      assert dummy_product_import.job_interval_in_seconds == "3600"
    end

    test "create_dummy_product_import/2 with invalid data returns error changeset" do
      scope = user_scope_fixture() |> default_application_scope_fixture()

      assert {:error, %Ecto.Changeset{}} =
               ExternalInventories.create_dummy_product_import(scope, @invalid_attrs)
    end

    test "update_dummy_product_import/3 with valid data updates the dummy_product_import" do
      scope = user_scope_fixture() |> default_application_scope_fixture()
      dummy_product_import = dummy_product_import_fixture(scope)

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        url: "some updated url",
        job_interval_in_seconds: "3600"
      }

      assert {:ok, %DummyProductImport{} = dummy_product_import} =
               ExternalInventories.update_dummy_product_import(
                 scope,
                 dummy_product_import,
                 update_attrs
               )

      assert dummy_product_import.name == "some updated name"
      assert dummy_product_import.description == "some updated description"
      assert dummy_product_import.url == "some updated url"
      assert dummy_product_import.job_interval_in_seconds == "3600"
    end

    test "update_dummy_product_import/3 with invalid scope raises" do
      scope = user_scope_fixture() |> default_application_scope_fixture()
      other_scope = user_scope_fixture() |> second_application_scope_fixture()
      dummy_product_import = dummy_product_import_fixture(scope)

      assert_raise MatchError, fn ->
        ExternalInventories.update_dummy_product_import(other_scope, dummy_product_import, %{})
      end
    end

    test "update_dummy_product_import/3 with invalid data returns error changeset" do
      scope = user_scope_fixture() |> default_application_scope_fixture()
      dummy_product_import = dummy_product_import_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               ExternalInventories.update_dummy_product_import(
                 scope,
                 dummy_product_import,
                 @invalid_attrs
               )

      assert dummy_product_import ==
               ExternalInventories.get_dummy_product_import!(scope, dummy_product_import.id)
    end

    test "delete_dummy_product_import/2 deletes the dummy_product_import" do
      scope = user_scope_fixture() |> default_application_scope_fixture()
      dummy_product_import = dummy_product_import_fixture(scope)

      assert {:ok, %DummyProductImport{}} =
               ExternalInventories.delete_dummy_product_import(scope, dummy_product_import)

      assert_raise Ecto.NoResultsError, fn ->
        ExternalInventories.get_dummy_product_import!(scope, dummy_product_import.id)
      end
    end

    test "delete_dummy_product_import/2 with invalid scope raises" do
      scope = user_scope_fixture() |> default_application_scope_fixture()
      other_scope = user_scope_fixture() |> second_application_scope_fixture()
      dummy_product_import = dummy_product_import_fixture(scope)

      assert_raise MatchError, fn ->
        ExternalInventories.delete_dummy_product_import(other_scope, dummy_product_import)
      end
    end

    test "change_dummy_product_import/2 returns a dummy_product_import changeset" do
      scope = user_scope_fixture() |> default_application_scope_fixture()
      dummy_product_import = dummy_product_import_fixture(scope)

      assert %Ecto.Changeset{} =
               ExternalInventories.change_dummy_product_import(scope, dummy_product_import)
    end
  end
end
