create_tenant = fn email, application_name, application_domain ->
  user =
    MainApp.Accounts.get_user_by_email(email)
    |> case do
      nil ->
        MainApp.AccountsFixtures.user_fixture(%{email: email})

      user ->
        user
    end

  application =
    MainApp.Repo.get_by(MainApp.Accounts.Application, %{name: application_name})
    |> case do
      nil ->
        {:ok, application} =
          MainApp.Accounts.create_application(MainApp.Accounts.Scope.for_user(user), %{
            name: application_name,
            subdomain: application_domain
          })

        application

      application ->
        application
    end

  MainApp.Repo.delete(user)
  MainApp.Tenants.run_tenant_migrations_to_tenant(application.tenant)
end

create_tenant.("myapp1@gmail.com", "myapp1", "myappone")
create_tenant.("myapp2@gmail.com", "myapp2", "myapptwo")

Mimic.copy(MainApp.ExternalInventories.DummyProductFetchAPI)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(MainApp.Repo, :manual)
