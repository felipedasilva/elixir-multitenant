defmodule MainApp.AccountsTest do
  use MainApp.DataCase, async: true

  alias MainApp.Accounts

  import MainApp.AccountsFixtures
  alias MainApp.Accounts.{User, UserToken, Application}

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture() |> set_password()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture() |> set_password()

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users without password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register_user(valid_user_attributes(email: email))
      assert user.email == email
      assert is_nil(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.utc_now()})
      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute Accounts.sudo_mode?(
               %User{authenticated_at: DateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute Accounts.sudo_mode?(%User{})
    end
  end

  describe "change_user_email/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = unconfirmed_user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert Accounts.update_user_email(user, token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_user_email(user, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(
          %User{},
          %{
            "password" => "new valid password"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, user, expired_tokens} =
        Accounts.update_user_password(user, %{
          password: "new valid password"
        })

      assert expired_tokens == []
      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, _, _} =
        Accounts.update_user_password(user, %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_magic_link_token/1" do
    setup do
      user = user_fixture()
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      %{user: user, token: encoded_token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_magic_link_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_magic_link_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_magic_link_token(token)
    end
  end

  describe "login_user_by_magic_link/1" do
    test "confirms user and expires tokens" do
      user = unconfirmed_user_fixture()
      refute user.confirmed_at
      {encoded_token, hashed_token} = generate_user_magic_link_token(user)

      assert {:ok, user, [%{token: ^hashed_token}]} =
               Accounts.login_user_by_magic_link(encoded_token)

      assert user.confirmed_at
    end

    test "returns user and (deleted) token for confirmed user" do
      user = user_fixture()
      assert user.confirmed_at
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      assert {:ok, ^user, []} = Accounts.login_user_by_magic_link(encoded_token)
      # one time use only
      assert {:error, :not_found} = Accounts.login_user_by_magic_link(encoded_token)
    end

    test "raises when unconfirmed user has password set" do
      user = unconfirmed_user_fixture()
      {1, nil} = Repo.update_all(User, set: [hashed_password: "hashed"])
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)

      assert_raise RuntimeError, ~r/magic link log in is not allowed/, fn ->
        Accounts.login_user_by_magic_link(encoded_token)
      end
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_login_instructions/2" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "login"
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "create_application/1" do
    test "requires name to be set" do
      attrs = %{}

      {:error, changeset} = Accounts.create_application(user_scope_fixture(), attrs)

      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates name to be set" do
      attrs = %{name: 123}

      {:error, changeset} = Accounts.create_application(user_scope_fixture(), attrs)

      assert %{name: ["is invalid"]} = errors_on(changeset)
    end

    test "requires subdomain to be set" do
      attrs = %{name: "test"}

      {:error, changeset} = Accounts.create_application(user_scope_fixture(), attrs)

      assert %{subdomain: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates subdomain to be set" do
      subdomains = ["test1", "te12te", "1234", "/123/@%"]

      subdomains
      |> Enum.each(fn subdomain ->
        attrs = %{name: "test", subdomain: subdomain}

        {:error, changeset} = Accounts.create_application(user_scope_fixture(), attrs)

        assert %{subdomain: ["must have only letters"]} = errors_on(changeset)
      end)
    end

    test "validates subdomain uniqueness" do
      Accounts.create_application(user_scope_fixture(), %{name: "app1", subdomain: "appone"})

      attrs = %{name: "test", subdomain: "appone"}

      {:error, changeset} =
        Accounts.create_application(user_scope_fixture(), attrs)

      assert %{subdomain: ["has already been taken"]} = errors_on(changeset)
    end

    test "create an application" do
      {:ok, application} =
        Accounts.create_application(user_scope_fixture(), %{name: "app1", subdomain: "appone"})

      refute is_nil(application.id)
      refute is_nil(application.tenant)
      assert "app1" == application.name
      assert "appone" == application.subdomain

      assert_enqueued worker: MainApp.Workers.TenantMigrationWorker,
                      args: %{
                        "application" => %{
                          "id" => application.id,
                          "tenant" => application.tenant,
                          "name" => application.name
                        }
                      },
                      queue: :migration
    end

    test "allow duplicate application names" do
      default_application = generate_default_application_fixture()

      assert "apptest" == default_application.name

      attrs = %{name: "apptest", subdomain: "apptesttwo"}

      {:ok, application} = Accounts.create_application(user_scope_fixture(), attrs)

      assert "apptest" == default_application.name
      assert default_application.id != application.id
    end
  end

  describe "link_user_to_application/2" do
    test "validates duplicate relation between user and application" do
      user = user_fixture()
      application = generate_default_application_fixture()

      {:ok, application_user} =
        Accounts.link_user_to_application(user, application)

      application_user |> Repo.preload([:user, :application])

      {:error, changeset} =
        Accounts.link_user_to_application(user, application)

      refute is_nil(errors_on(changeset))
    end

    test "link user to application" do
      user = user_fixture()
      application = generate_default_application_fixture()

      {:ok, application_user} =
        Accounts.link_user_to_application(user, application)

      application_user = application_user |> Repo.preload([:user, :application])

      refute is_nil(application_user.id)
      assert application.id == application_user.application.id
      assert user.id == application_user.user.id
    end
  end

  describe "list_applications/1" do
    test "retrieve all applications linked to the user" do
      Accounts.create_application(user_scope_fixture(), %{name: "notvalid", subdomain: "notvalid"})

      scope = user_scope_fixture(user_fixture(%{email: "test@gmail.com"}))
      application = generate_default_application_fixture()
      Accounts.link_user_to_application(scope.user, application)

      applications = Accounts.list_applications(scope)

      assert 1 == applications |> length()
      assert application == applications |> List.first()
    end
  end

  describe "get_application!/2" do
    test "should not retrive application" do
      scope = user_scope_fixture(user_fixture(%{email: "test@gmail.com"}))

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_application!(scope, 9999)
      end
    end

    test "should not return applications that are not linked to the user" do
      application_notvalid = generate_default_application_fixture()
      scope = user_scope_fixture(user_fixture(%{email: "test@gmail.com"}))

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_application!(scope, application_notvalid.id)
      end
    end

    test "retrieve the correct application" do
      Accounts.create_application(user_scope_fixture(), %{name: "notvalid", subdomain: "notvalid"})

      scope = user_scope_fixture(user_fixture(%{email: "test@gmail.com"}))

      default_application = generate_default_application_fixture()
      Accounts.link_user_to_application(scope.user, default_application)

      application = Accounts.get_application!(scope, default_application.id)
      refute is_nil(application)
      assert default_application.id == application.id
      assert default_application.name == application.name
    end
  end

  describe "get_application_by_id!/1" do
    test "should not retrive application" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_application_by_id!(9999)
      end
    end

    test "retrieve the correct application" do
      Accounts.create_application(user_scope_fixture(), %{name: "notvalid"})

      scope = user_scope_fixture(user_fixture(%{email: "test@gmail.com"}))
      correct_application = generate_default_application_fixture()
      Accounts.link_user_to_application(scope.user, correct_application)

      application = Accounts.get_application_by_id!(correct_application.id)

      assert correct_application.id == application.id
      assert correct_application.name == application.name
      assert correct_application.name == application.name
    end
  end

  describe "update_application/2" do
    test "should not be able to change applications that are not linked to the user" do
      application_notvalid = generate_default_application_fixture()
      scope = user_scope_fixture(user_fixture(%{email: "test@gmail.com"}))

      {:error, error} =
        Accounts.update_application(scope, application_notvalid, %{name: "apptest2"})

      assert "User not linked to the application" == error
    end

    test "should be able to change applications that are linked to the user" do
      scope = user_scope_fixture(user_fixture(%{email: "test@gmail.com"}))
      application_default = application = generate_default_application_fixture()
      Accounts.link_user_to_application(scope.user, application)

      {:ok, application_updated} =
        Accounts.update_application(scope, application_default, %{name: "test2"})

      assert application_default.id == application_updated.id
      assert "test2" == application_updated.name
    end
  end

  describe "delete_application/2" do
    test "should not be able to delete applications that are not linked to the user" do
      application_notvalid = generate_default_application_fixture()
      scope = user_scope_fixture(user_fixture(%{email: "test@gmail.com"}))

      {:error, error} = Accounts.delete_application(scope, application_notvalid)

      assert "User not linked to the application" == error
    end

    test "should be able to delete applications that are linked to the user" do
      scope = user_scope_fixture(user_fixture(%{email: "test@gmail.com"}))
      application_default = application = generate_default_application_fixture()
      Accounts.link_user_to_application(scope.user, application)

      {:ok, application_deleted} = Accounts.delete_application(scope, application_default)

      assert application_default.id == application_deleted.id
      assert is_nil(Repo.get(Application, application_deleted.id))
    end
  end
end
