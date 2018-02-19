defmodule Incunabula.AdminController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  @usersDB "users.db"

  plug :authenticate_admin when action in [:index, :adduser, :deleteuser]

  def index(conn, _params, _user) do
    dir       = Path.join(Incunabula.Git.get_books_dir(), "../users")
    usersdb   = IncunabulaUtilities.DB.getDB(dir, @usersDB)
    users     = for u <- usersdb, do: Map.get(u, :username)
    changeset = Incunabula.Login.changeset
    render conn, "index.html",
      books_directory:  dir,
      users:            users,
      adduserchangeset: changeset,
      adduser:          "/admin/adduser",
      changepassword:   "/admin/changepassword"
  end

  def adduser(conn, %{"login" => login}, _user) do
    %{"username" => username,
      "password" => password} = login
    case IncunabulaUtilities.Users.add_user(username, password) do
      :ok ->
        conn
        |> redirect(to: "/admin")
      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> redirect(to: "/admin")
    end
  end

  def changepassword(conn, %{"login" => login}, _user) do
    %{"username" => username,
      "password" => password} = login
    case IncunabulaUtilities.Users.change_password(username, password) do
      :ok ->
        conn
        |> redirect(to: "/admin")
      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> redirect(to: "/admin")
    end
  end

  def deleteuser(conn, %{"username" => username}, _user) do
    # don't delete the admin user bro
    case username do
      "admin" ->
        :ok
      _other ->
        _dir = IncunabulaUtilities.Users.delete_user(username)
        # now we push the new users list to the front end
        # we have to do it here because all this stuff is not available
        # at compile time in the dependency `incunabula_utilities`
        users = IncunabulaUtilities.Users.get_users()
        html  = Incunabula.FragController.get_users(users)
        # No, I don't know why it takes books for channel details
        Incunabula.Endpoint.broadcast "admin:get_users", "books", %{books: html}
    end
    conn
    |> redirect(to: "/admin")
  end

end
