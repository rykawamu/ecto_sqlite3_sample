defmodule TeckFanzine.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias TeckFanzine.Repo

  alias TeckFanzine.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
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

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  alias TeckFanzine.Accounts.{AccountsUser, AccountsUserToken, AccountsUserNotifier}

  ## Database getters

  @doc """
  Gets a accounts_user by email.

  ## Examples

      iex> get_accounts_user_by_email("foo@example.com")
      %AccountsUser{}

      iex> get_accounts_user_by_email("unknown@example.com")
      nil

  """
  def get_accounts_user_by_email(email) when is_binary(email) do
    Repo.get_by(AccountsUser, email: email)
  end

  @doc """
  Gets a accounts_user by email and password.

  ## Examples

      iex> get_accounts_user_by_email_and_password("foo@example.com", "correct_password")
      %AccountsUser{}

      iex> get_accounts_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_accounts_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    accounts_user = Repo.get_by(AccountsUser, email: email)
    if AccountsUser.valid_password?(accounts_user, password), do: accounts_user
  end

  @doc """
  Gets a single accounts_user.

  Raises `Ecto.NoResultsError` if the AccountsUser does not exist.

  ## Examples

      iex> get_accounts_user!(123)
      %AccountsUser{}

      iex> get_accounts_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_accounts_user!(id), do: Repo.get!(AccountsUser, id)

  ## Accounts user registration

  @doc """
  Registers a accounts_user.

  ## Examples

      iex> register_accounts_user(%{field: value})
      {:ok, %AccountsUser{}}

      iex> register_accounts_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_accounts_user(attrs) do
    %AccountsUser{}
    |> AccountsUser.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking accounts_user changes.

  ## Examples

      iex> change_accounts_user_registration(accounts_user)
      %Ecto.Changeset{data: %AccountsUser{}}

  """
  def change_accounts_user_registration(%AccountsUser{} = accounts_user, attrs \\ %{}) do
    AccountsUser.registration_changeset(accounts_user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the accounts_user email.

  ## Examples

      iex> change_accounts_user_email(accounts_user)
      %Ecto.Changeset{data: %AccountsUser{}}

  """
  def change_accounts_user_email(accounts_user, attrs \\ %{}) do
    AccountsUser.email_changeset(accounts_user, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_accounts_user_email(accounts_user, "valid password", %{email: ...})
      {:ok, %AccountsUser{}}

      iex> apply_accounts_user_email(accounts_user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_accounts_user_email(accounts_user, password, attrs) do
    accounts_user
    |> AccountsUser.email_changeset(attrs)
    |> AccountsUser.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the accounts_user email using the given token.

  If the token matches, the accounts_user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_accounts_user_email(accounts_user, token) do
    context = "change:#{accounts_user.email}"

    with {:ok, query} <- AccountsUserToken.verify_change_email_token_query(token, context),
         %AccountsUserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(accounts_user_email_multi(accounts_user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp accounts_user_email_multi(accounts_user, email, context) do
    changeset = accounts_user |> AccountsUser.email_changeset(%{email: email}) |> AccountsUser.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:accounts_user, changeset)
    |> Ecto.Multi.delete_all(:tokens, AccountsUserToken.accounts_user_and_contexts_query(accounts_user, [context]))
  end

  @doc """
  Delivers the update email instructions to the given accounts_user.

  ## Examples

      iex> deliver_update_email_instructions(accounts_user, current_email, &Routes.accounts_user_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%AccountsUser{} = accounts_user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, accounts_user_token} = AccountsUserToken.build_email_token(accounts_user, "change:#{current_email}")

    Repo.insert!(accounts_user_token)
    AccountsUserNotifier.deliver_update_email_instructions(accounts_user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the accounts_user password.

  ## Examples

      iex> change_accounts_user_password(accounts_user)
      %Ecto.Changeset{data: %AccountsUser{}}

  """
  def change_accounts_user_password(accounts_user, attrs \\ %{}) do
    AccountsUser.password_changeset(accounts_user, attrs, hash_password: false)
  end

  @doc """
  Updates the accounts_user password.

  ## Examples

      iex> update_accounts_user_password(accounts_user, "valid password", %{password: ...})
      {:ok, %AccountsUser{}}

      iex> update_accounts_user_password(accounts_user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_accounts_user_password(accounts_user, password, attrs) do
    changeset =
      accounts_user
      |> AccountsUser.password_changeset(attrs)
      |> AccountsUser.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:accounts_user, changeset)
    |> Ecto.Multi.delete_all(:tokens, AccountsUserToken.accounts_user_and_contexts_query(accounts_user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{accounts_user: accounts_user}} -> {:ok, accounts_user}
      {:error, :accounts_user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_accounts_user_session_token(accounts_user) do
    {token, accounts_user_token} = AccountsUserToken.build_session_token(accounts_user)
    Repo.insert!(accounts_user_token)
    token
  end

  @doc """
  Gets the accounts_user with the given signed token.
  """
  def get_accounts_user_by_session_token(token) do
    {:ok, query} = AccountsUserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(AccountsUserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given accounts_user.

  ## Examples

      iex> deliver_accounts_user_confirmation_instructions(accounts_user, &Routes.accounts_user_confirmation_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_accounts_user_confirmation_instructions(confirmed_accounts_user, &Routes.accounts_user_confirmation_url(conn, :edit, &1))
      {:error, :already_confirmed}

  """
  def deliver_accounts_user_confirmation_instructions(%AccountsUser{} = accounts_user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if accounts_user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, accounts_user_token} = AccountsUserToken.build_email_token(accounts_user, "confirm")
      Repo.insert!(accounts_user_token)
      AccountsUserNotifier.deliver_confirmation_instructions(accounts_user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a accounts_user by the given token.

  If the token matches, the accounts_user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_accounts_user(token) do
    with {:ok, query} <- AccountsUserToken.verify_email_token_query(token, "confirm"),
         %AccountsUser{} = accounts_user <- Repo.one(query),
         {:ok, %{accounts_user: accounts_user}} <- Repo.transaction(confirm_accounts_user_multi(accounts_user)) do
      {:ok, accounts_user}
    else
      _ -> :error
    end
  end

  defp confirm_accounts_user_multi(accounts_user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:accounts_user, AccountsUser.confirm_changeset(accounts_user))
    |> Ecto.Multi.delete_all(:tokens, AccountsUserToken.accounts_user_and_contexts_query(accounts_user, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given accounts_user.

  ## Examples

      iex> deliver_accounts_user_reset_password_instructions(accounts_user, &Routes.accounts_user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_accounts_user_reset_password_instructions(%AccountsUser{} = accounts_user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, accounts_user_token} = AccountsUserToken.build_email_token(accounts_user, "reset_password")
    Repo.insert!(accounts_user_token)
    AccountsUserNotifier.deliver_reset_password_instructions(accounts_user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the accounts_user by reset password token.

  ## Examples

      iex> get_accounts_user_by_reset_password_token("validtoken")
      %AccountsUser{}

      iex> get_accounts_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_accounts_user_by_reset_password_token(token) do
    with {:ok, query} <- AccountsUserToken.verify_email_token_query(token, "reset_password"),
         %AccountsUser{} = accounts_user <- Repo.one(query) do
      accounts_user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the accounts_user password.

  ## Examples

      iex> reset_accounts_user_password(accounts_user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %AccountsUser{}}

      iex> reset_accounts_user_password(accounts_user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_accounts_user_password(accounts_user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:accounts_user, AccountsUser.password_changeset(accounts_user, attrs))
    |> Ecto.Multi.delete_all(:tokens, AccountsUserToken.accounts_user_and_contexts_query(accounts_user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{accounts_user: accounts_user}} -> {:ok, accounts_user}
      {:error, :accounts_user, changeset, _} -> {:error, changeset}
    end
  end
end
