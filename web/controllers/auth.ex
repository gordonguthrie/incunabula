defmodule Incunabula.Auth do
  import Plug.Conn
  import Phoenix.Controller

  def init([]) do
    users = Incunabula.Users.get_users()
    users
  end

  def call(conn, opts) do
    user_id = get_session(conn, :user_id)
    assign(conn, :current_user, user_id)
  end

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: "/")
      |> halt()
    end
  end

end
