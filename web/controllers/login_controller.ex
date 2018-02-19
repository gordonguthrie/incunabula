defmodule Incunabula.LoginController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  def index(conn, _params, _user) do
    changeset = Incunabula.Login.changeset
    render conn, "index.html",
      changeset: changeset
  end

  def login(conn, %{"login" => login}, _user) do
    %{"username" => username,
      "password" => password} = login
    case IncunabulaUtilities.Users.is_login_valid?(username, password) do
      true ->
        conn
        |> put_session(:user_id, username)
        |> assign(:current_user, username)
        |> configure_session(renew: true)
        |> redirect(to: "/")
      false ->
        conn
        |> put_flash(:error, "Invalid login")
        |> redirect(to: "/login")
    end
  end

  def logout(conn, _params, _user) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

end
