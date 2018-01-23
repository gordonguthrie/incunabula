defmodule Incunabula.AdminController do
  use Incunabula.Web, :controller

  plug :authenticate_user when action in [:index]

  def index(conn, _params) do
    books     = Incunabula.Git.get_books()
    dir       = Incunabula.Git.get_books_dir()
    users     = IncunabulaUtilities.Users.get_users()
    changeset = Incunabula.Book.changeset()
    render conn, "index.html",
      books_directory: dir,
      books:           books,
      users:           users,
      changeset:       changeset
   end

end
