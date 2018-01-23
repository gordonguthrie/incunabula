defmodule Incunabula.LoginController do
  use Incunabula.Web, :controller

  def index(conn, _params) do
    changeset = Incunabula.Login.changeset
    render conn, "index.html",
      changeset: changeset
  end

  def login(conn, %{"login" => login}) do
    %{"username" => username,
      "password" => password} = login
    case IncunabulaUtilities.Users.is_login_valid(username, password) do
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

end
