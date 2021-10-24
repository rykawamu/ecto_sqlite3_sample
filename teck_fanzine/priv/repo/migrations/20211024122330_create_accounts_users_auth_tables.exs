defmodule TeckFanzine.Repo.Migrations.CreateAccountsUsersAuthTables do
  use Ecto.Migration

  def change do
    create table(:accounts_users) do
      add :email, :string, null: false, collate: :nocase
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:accounts_users, [:email])

    create table(:accounts_users_tokens) do
      add :accounts_user_id, references(:accounts_users, on_delete: :delete_all), null: false
      add :token, :binary, null: false, size: 32
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:accounts_users_tokens, [:accounts_user_id])
    create unique_index(:accounts_users_tokens, [:context, :token])
  end
end
