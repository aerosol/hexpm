defmodule Hexpm.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  imports other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      alias Hexpm.Repo
      alias Hexpm.Fake

      import Ecto
      import Ecto.Query, only: [from: 2]
      import Hexpm.Web.Router.Helpers
      import Hexpm.TestHelpers
      import Hexpm.Case
      import Hexpm.Factory
      import unquote(__MODULE__)

      # The default endpoint for testing
      @endpoint Hexpm.Web.Endpoint
    end
  end

  setup tags do
    opts = tags |> Map.take([:isolation]) |> Enum.to_list()
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Hexpm.Repo, opts)
    Hexpm.Case.reset_store(tags)
    Bamboo.SentEmail.reset
    :ok
  end

  # See: https://github.com/elixir-lang/plug/issues/455
  def my_put_session(conn, key, value) do
    private =
      conn.private
      |> Map.update(:plug_session, %{key => value}, &Map.put(&1, key, value))
      |> Map.put(:plug_session_fetch, :bypass)
    %{conn | private: private}
  end

  def test_login(conn, user) do
    user = Hexpm.Accounts.Users.sign_in(user)

    conn
    |> my_put_session("username", user.username)
    |> my_put_session("key", user.session_key)
  end

  def json_post(conn, path, params) do
    conn
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Phoenix.ConnTest.dispatch(Hexpm.Web.Endpoint, :post, path, Poison.encode!(params))
  end
end
