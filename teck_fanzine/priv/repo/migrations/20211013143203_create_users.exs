defmodule TeckFanzine.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :age, :integer
      add :handle, :string

      timestamps()
    end
  end
end
