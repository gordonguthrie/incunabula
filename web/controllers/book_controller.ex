defmodule Incunabula.BookController do
  use Incunabula.Web, :controller

  plug :authenticate_user when action in [:index]

  def index(conn, _params) do
    render conn, "index.html"
  end

  def show(conn, _params) do
    render conn, "show.html"
  end

  def create(conn, %{"book" => book}) do
    %{"book_title" => book_title} = book
    case Incunabula.Git.create_book(book_title) do
      :ok ->
        conn
        |> redirect(to: "/books/" <> book_title)
      {:error, err} ->
        conn
        |> put_flash(:error, err)
        |> render("index.html")
    end
  end

end
