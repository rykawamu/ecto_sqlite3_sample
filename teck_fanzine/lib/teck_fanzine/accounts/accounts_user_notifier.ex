defmodule TeckFanzine.Accounts.AccountsUserNotifier do
  import Swoosh.Email

  alias TeckFanzine.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"MyApp", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(accounts_user, url) do
    deliver(accounts_user.email, "Confirmation instructions", """

    ==============================

    Hi #{accounts_user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a accounts_user password.
  """
  def deliver_reset_password_instructions(accounts_user, url) do
    deliver(accounts_user.email, "Reset password instructions", """

    ==============================

    Hi #{accounts_user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a accounts_user email.
  """
  def deliver_update_email_instructions(accounts_user, url) do
    deliver(accounts_user.email, "Update email instructions", """

    ==============================

    Hi #{accounts_user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
