defmodule Spherium.AttemptController do
  use Spherium.Web, :controller

  import Ecto.Query, only: [where: 2]

  alias Spherium.Attempt

  plug :authenticate_user
  plug :authorize_user, [:all, :self]
  plug :apply_policy when action in [:index]

  def index(conn, _params) do
    filters =
      Ecto.Changeset.cast(%Attempt{}, conn.query_params, [:username, :success])
      |> Map.fetch(:changes)
      |> Kernel.elem(1)
      |> Map.to_list()

    attempts =
      Attempt
      |> where(^filters)
      |> Repo.all()

    render(conn, "index.json", attempts: attempts)
  end

  def show(conn, %{"id" => id}) do
    attempt = Repo.get!(Attempt, id)

    if attempt.username != conn.assigns[:user].username and
       conn.assigns[:permission_type] == :self,
       do: raise InsufficientScopeError

    render(conn, "show.json", attempt: attempt)
  end
end
