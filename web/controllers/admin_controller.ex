defmodule Incunabula.AdminController do
  use Incunabula.Web, :controller

  plug :authenticate_user when action in [:index]

  def index(conn, _params) do
    dir = get_env(:books_directory)
    IO.inspect dir
    books = Incunabula.Git.get_books(dir)
    users = IncunabulaUtilities.Users.get_users()
    render conn, "index.html",
      books_directory: dir,
      books:           books,
      users:           users
   end

  defp get_env(key) do
    configs = Application.get_env(:incunabula, :books_settings)
    configs[key]
  end

end
