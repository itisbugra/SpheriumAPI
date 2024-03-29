defmodule Spherium.Passphrase do
  use Spherium.Web, :model

  @uuid_regex ~r|[0-9,a-z,A-Z]{8}-[0-9,a-z,A-Z]{4}-[0-9,a-z,A-Z]{4}-[0-9,a-z,A-Z]{4}-[0-9,a-z,A-Z]{12}|

  schema "passphrases" do
    field :passkey, :string
    belongs_to :user, Spherium.User
    field :device, Ecto.UUID
    field :user_agent, :string
    field :inserted_at, :naive_datetime
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:passkey, :user_id, :device, :user_agent])
    |> validate_required([:passkey, :user_id, :device, :user_agent])
    |> validate_format(:device, @uuid_regex)
    |> foreign_key_constraint(:user_id)
  end
end
