defmodule Spherium.Repo.Migrations.AddOneTimeCodesAndRelatedTables do
  use Ecto.Migration

  def change do
    create table(:one_time_codes) do
      add :user_id, references(:users, on_delete: :delete_all, on_update: :update_all), null: false
      add :code, :integer, null: false
      add :device, :uuid, null: false
      add :user_agent, :string, null: false
      add :inserted_at, :naive_datetime, null: false, default: fragment("now()")
    end

    create constraint(:one_time_codes, :code_must_be_between_100000_999999, check: "(code >= 100000) AND (code <= 999999)")

    create index(:one_time_codes, [:code])

    create table(:one_time_code_invalidations) do
      add :one_time_code_id, references(:one_time_codes, on_delete: :delete_all, on_update: :update_all), primary_key: true
      add :inserted_at, :naive_datetime, null: false, default: fragment("now()")
    end

    create table(:unbans) do
      add :user_id, references(:users, on_delete: :delete_all, on_update: :update_all), null: false
      add :inserted_at, :naive_datetime, null: false, default: fragment("now()")
    end

    alter table(:passphrases) do
      remove :user_id
      add :one_time_code_id, references(:one_time_codes, on_delete: :delete_all, on_update: :update_all), null: false
      remove :device
      remove :user_agent
    end

    create index(:passphrases, [:one_time_code_id], unique: true)
  end
end
