defmodule Incunabula.AdminController do
  use Incunabula.Web, :controller

  plug :authenticate_user when action in [:index]

  def index(conn, _params) do
    dir       = Incunabula.Git.get_books_dir()
    users     = IncunabulaUtilities.Users.get_users()
    render conn, "index.html",
      books_directory: dir,
      users:           users
  end

end
