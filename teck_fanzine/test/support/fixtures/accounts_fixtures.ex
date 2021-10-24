defmodule TeckFanzine.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TeckFanzine.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        age: 42,
        handle: "some handle",
        name: "some name"
      })
      |> TeckFanzine.Accounts.create_user()

    user
  end

  def unique_accounts_user_email, do: "accounts_user#{System.unique_integer()}@example.com"
  def valid_accounts_user_password, do: "hello world!"

  def valid_accounts_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_accounts_user_email(),
      password: valid_accounts_user_password()
    })
  end

  def accounts_user_fixture(attrs \\ %{}) do
    {:ok, accounts_user} =
      attrs
      |> valid_accounts_user_attributes()
      |> TeckFanzine.Accounts.register_accounts_user()

    accounts_user
  end

  def extract_accounts_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
