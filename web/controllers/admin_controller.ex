defmodule Incunabula.AdminController do
  use Incunabula.Web, :controller

  def index(conn, _params) do
    dir = get_env(:books_directory)
    IO.inspect dir
    books = Incunabula.Git.get_books(dir)
    users = get_users()
    render conn, "index.html",
      books_directory: dir,
      books:           books,
      users:           users
   end

  defp get_env(key) do
    configs = Application.get_env(:incunabula, :books_settings)
    configs[key]
  end

  defp get_users() do
    path = Path.join(:code.priv_dir(:incunabula), "users/users.config")
    {:ok, [users: users]} = :file.consult(path)
    for {user, password} <- users, do: user
  end

end
