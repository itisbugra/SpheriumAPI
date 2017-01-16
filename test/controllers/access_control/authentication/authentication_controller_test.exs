defmodule Spherium.AuthenticationControllerTest do
  use Spherium.ConnCase

  @tag super_cow_powers: false

  alias Spherium.Factory

  describe "instantiation of concrete authentication" do
    test "returns passphrase if user preferred insecure authentication scheme", %{conn: conn} do
      user = Factory.insert(:user, password: "123456", authentication_scheme: :insecure)

      conn = post conn,
                  authentication_path(conn, :create),
                  credentials: %{
                    username: user.username,
                    password: "123456",
                    device: Ecto.UUID.generate(),
                    user_agent: "Test user agent"
                  }

      data = json_response(conn, 201)["data"]

      assert data
      assert data["authentication_scheme"] == "insecure"
      assert data["passphrase_id"]
      assert data["passkey"]
    end

    test "returns user identifier with two factor authentication over OTC scheme", %{conn: conn} do
      user = Factory.insert(:user, password: "123456", authentication_scheme: :two_factor_over_otc)

      conn = post conn,
                  authentication_path(conn, :create),
                  credentials: %{
                    username: user.username,
                    password: "123456",
                    device: Ecto.UUID.generate(),
                    user_agent: "Test user agent"
                  }

      data = json_response(conn, 201)["data"]

      assert data["user_id"] == user.id
      assert data["authentication_scheme"] == "two_factor_over_otc"
      refute data["passphrase_id"]
      refute data["passkey"]
    end

    test "returns user identifier with two factor authentication over TBC scheme", %{conn: conn} do
      user = Factory.insert(:user, password: "123456", authentication_scheme: :two_factor_over_tbc)

      conn = post conn,
                  authentication_path(conn, :create),
                  credentials: %{
                    username: user.username,
                    password: "123456",
                    device: Ecto.UUID.generate(),
                    user_agent: "Test user agent"
                  }

      # data = json_response(conn, 201)["data"]
      #
      # assert data["user_id"] == user.id
      # assert data["authentication_scheme"] == "two_factor_over_tbc"
      # refute data["passphrase_id"]
      # refute data["passkey"]

      assert text_response(conn, :not_implemented) =~ "TBC is not available currently."
    end

    test "returns 422 on invalid credentials", %{conn: conn} do
      conn = post conn,
                  authentication_path(conn, :create),
                  credentials: %{
                    username: "username",
                    device: Ecto.UUID.generate(),
                    user_agent: "Test user agent"
                  }

      assert json_response(conn, 422)["errors"]["password"] == ["can't be blank"]
    end

    test "returns 403 on invalid username/password combination", %{conn: conn} do
      user = Factory.insert(:user, password: "123456")

      conn = post conn,
                  authentication_path(conn, :create),
                  credentials: %{
                    username: user.username,
                    password: "1234567",
                    device: Ecto.UUID.generate(),
                    user_agent: "Test user agent"
                  }

      assert text_response(conn, :forbidden) =~ "Invalid username/password combination."
    end

    test "returns 409 when passphrase quota exceeded", %{conn: conn} do
      user = Factory.insert(:user, password: "123456")

      Factory.insert_list(5, :passphrase, user: user)

      conn = post conn,
                  authentication_path(conn, :create),
                  credentials: %{
                    username: user.username,
                    password: "123456",
                    device: Ecto.UUID.generate(),
                    user_agent: "Test user agent"
                  }

      assert text_response(conn, :conflict) =~ "Maximum number of passphrases available is reached (5)."
    end

    test "returns 429 when OTC quota exceeded", %{conn: conn} do
      user = Factory.insert(:user, password: "123456", authentication_scheme: :two_factor_over_otc)

      Factory.insert_list(2, :one_time_code, user_id: user.id)

      conn = post conn,
                  authentication_path(conn, :create),
                  credentials: %{
                    username: user.username,
                    password: "123456",
                    device: Ecto.UUID.generate(),
                    user_agent: "Test user agent"
                  }

      assert text_response(conn, :too_many_requests) =~ "OTC quota per 15 minutes is reached (2)."
    end
  end

  describe "finalization of concrete authentication with one time code" do
    test "creates a new passphrase upon valid one time code", %{conn: conn} do
      user = Factory.insert(:user, password: "123456")
      otc = Factory.insert(:one_time_code, user: user)

      conn = post conn,
                  authentication_path(conn, :create),
                  one_time_code_submission: %{code: otc.code,
                                              user_id: user.id}

      data = json_response(conn, 201)["data"]

      assert data
      assert data["passkey"]
      assert data["passphrase_id"]
    end

    test "does not create a passphrase with expired one time code", %{conn: conn} do
      user = Factory.insert(:user, password: "123456")
      otc = Factory.insert(:one_time_code,
                           user: user,
                           inserted_at: NaiveDateTime.from_erl!({{2000, 1, 1}, {13, 30, 15}}))

      conn = post conn,
                  authentication_path(conn, :create),
                  one_time_code_submission: %{code: otc.code,
                                              user_id: user.id}

      assert text_response(conn, 404) =~ "Pair not found."
    end

    test "does not create a passphrase with no one time code generated", %{conn: conn} do
      user = Factory.insert(:user, password: "123456")

      conn = post conn,
                  authentication_path(conn, :create),
                  one_time_code_submission: %{code: 100000,
                                              user_id: user.id}

      assert text_response(conn, 404) =~ "Pair not found."
    end

    test "rejects request if given code is invalid", %{conn: conn} do
      user = Factory.insert(:user, password: "123456")
      _otc = Factory.insert(:one_time_code,
                            user: user,
                            inserted_at: NaiveDateTime.from_erl!({{2000, 1, 1}, {13, 30, 15}}))

      conn = post conn,
                  authentication_path(conn, :create),
                  one_time_code_submission: %{code: 1000000,
                                              user_id: user.id}

      assert conn.status == 422
    end

    test "rejects request if given code does not match", %{conn: conn} do
      user = Factory.insert(:user, password: "123456")
      _otc = Factory.insert(:one_time_code,
                            user: user)

      conn = post conn,
                  authentication_path(conn, :create),
                  one_time_code_submission: %{code: 100001,
                                              user_id: user.id}

      assert text_response(conn, 404) =~ "Pair not found."
    end

    test "checks for already satisfied one time code", %{conn: conn} do
      user = Factory.insert(:user, password: "123456")
      otc = Factory.insert(:one_time_code,
                           user: user)

      # Fulfill the code
      Factory.insert(:passphrase, user: user, one_time_code: otc)

      conn = post conn,
                  authentication_path(conn, :create),
                  one_time_code_submission: %{code: otc.code,
                                              user_id: user.id}

      assert text_response(conn, 404) =~ "Pair not found."
    end

    test "checks for already invalidated one time code", %{conn: conn} do
      user = Factory.insert(:user, password: "123456")
      otc = Factory.insert(:one_time_code,
                           user: user)

      # Invalidate that code
      Factory.insert(:one_time_code_invalidation, one_time_code: otc)

      conn = post conn,
                  authentication_path(conn, :create),
                  one_time_code_submission: %{code: otc.code,
                                              user_id: user.id}

      assert text_response(conn, 404) =~ "Pair not found."
    end
  end
end
