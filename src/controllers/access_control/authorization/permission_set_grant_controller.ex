defmodule Spherium.PermissionSetGrantController do
  use Spherium.Web, :controller

  alias Spherium.PermissionSetGrant

  plug :authenticate_user
  plug :authorize_user, [:all, :self]

  def index(conn, _params) do
    permission_set_grants = Repo.all(PermissionSetGrant)

    render(conn, "index.json", permission_set_grants: permission_set_grants)
  end

  def show(conn, %{"id" => id}) do
    permission_set_grant = Repo.get!(PermissionSetGrant, id)

    render(conn, "show.json", permission_set_grant: permission_set_grant)
  end
end
