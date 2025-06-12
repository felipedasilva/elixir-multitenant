defmodule MainApp.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias MainApp.Accounts.Scope
  alias MainApp.Tenants
  alias MainApp.Repo

  alias MainApp.Accounts.{User, UserToken, UserNotifier, Application, ApplicationUser}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.email_changeset(attrs)
    |> Repo.insert()
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `MainApp.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset = User.email_changeset(user, %{email: email})

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `MainApp.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, %User{}, [...]}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
    |> case do
      {:ok, user, expired_tokens} -> {:ok, user, expired_tokens}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, user, []}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc ~S"""
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    %{data: %User{} = user} = changeset

    with {:ok, %{user: user, tokens_to_expire: expired_tokens}} <-
           Ecto.Multi.new()
           |> Ecto.Multi.update(:user, changeset)
           |> Ecto.Multi.all(
             :tokens_to_expire,
             UserToken.by_user_and_contexts_query(user, :all)
           )
           |> Ecto.Multi.delete_all(:tokens, fn %{tokens_to_expire: tokens_to_expire} ->
             UserToken.delete_all_query(tokens_to_expire)
           end)
           |> Repo.transaction() do
      {:ok, user, expired_tokens}
    end
  end

  def create_application(%Scope{user: %User{}} = scope, attrs \\ %{}) do
    changeset = Application.changeset(%Application{}, attrs)

    if not changeset.valid? do
      {:error, changeset}
    else
      create_application_with_user(scope, changeset)
    end
  end

  defp create_application_with_user(%Scope{user: %User{} = user}, changeset) do
    with {:ok, %{application: application, application_user: _}} <-
           Ecto.Multi.new()
           |> Ecto.Multi.insert(:application, changeset)
           |> Ecto.Multi.insert(:application_user, fn %{application: application} ->
             create_user_application(user, application)
           end)
           |> Ecto.Multi.insert(:oban_job, fn %{application: application} ->
             MainApp.Workers.TenantMigrationWorker.new(%{"application" => application})
           end)
           |> Repo.transaction() do
      {:ok, application}
    end
  end

  def create_application_and_run_migrations(attrs \\ %{}) do
    {:ok, application} =
      %Application{}
      |> Application.changeset(attrs)
      |> Repo.insert()

    Tenants.run_tenant_migrations_to_tenant(application.tenant)

    application
  end

  def link_user_to_application(%User{} = user, %Application{} = application) do
    create_user_application(user, application)
    |> Repo.insert()
  end

  defp create_user_application(%User{} = user, %Application{} = application) do
    %ApplicationUser{}
    |> ApplicationUser.changeset(%{application_id: application.id, user_id: user.id})
  end

  def list_applications(%Scope{user: %User{} = user}) do
    from(a in Application,
      join: au in "application_users",
      on: au.application_id == a.id,
      where: au.user_id == ^user.id
    )
    |> Repo.all()
  end

  def get_application!(%Scope{user: %User{} = user}, application_id) do
    from(a in Application,
      join: au in "application_users",
      on: au.application_id == a.id,
      where: au.user_id == ^user.id and a.id == ^application_id
    )
    |> Repo.one!()
  end

  def get_application_by_id!(application_id) do
    Repo.get!(Application, application_id)
  end

  def get_application_by_subdomain(%Scope{}, subdomain) do
    Repo.get_by(Application, subdomain: subdomain)
  end

  def change_application(%Application{} = application, attrs \\ %{}) do
    Application.changeset(application, attrs)
  end

  def update_application(%Scope{user: %User{} = user}, %Application{} = application, attrs \\ %{}) do
    is_user_linked_to_application(user, application)
    |> case do
      {:ok, _} ->
        application |> change_application(attrs) |> Repo.update()

      {:error, e} ->
        {:error, e}
    end
  end

  def delete_application(%Scope{user: %User{} = user}, %Application{} = application) do
    is_user_linked_to_application(user, application)
    |> case do
      {:ok, _} ->
        Repo.delete(application)

      {:error, e} ->
        {:error, e}
    end
  end

  defp is_user_linked_to_application(%User{} = user, %Application{} = application) do
    from(au in ApplicationUser,
      where: au.user_id == ^user.id and au.application_id == ^application.id
    )
    |> Repo.one()
    |> case do
      application_user when not is_nil(application_user) ->
        {:ok, application_user}

      nil ->
        {:error, "User not linked to the application"}

      _ ->
        {:error, "Unknown error"}
    end
  end
end
