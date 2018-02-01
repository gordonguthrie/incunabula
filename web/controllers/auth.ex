defmodule Incunabula.Auth do
  import Plug.Conn
  import Phoenix.Controller

  def init([]) do
    users = IncunabulaUtilities.Users.get_users()
    users
  end

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)
    put_current_user(conn, user_id)
  end

  def authenticate_user(conn, _opts) do
    cond do
      user = conn.assigns.current_user ->
        conn
        |> put_current_user(user)
    true ->
        conn
        |> put_flash(:error, "You must be logged in to access that page")
        |> redirect(to: "/")
        |> halt()
    end
  end

  defp put_current_user(conn, user) do
    IO.inspect user
    token = Phoenix.Token.sign(conn, "user socket", user)
    conn
    |> assign(:current_user, user)
    |> assign(:user_token, token)
  end
end
