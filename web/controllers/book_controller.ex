defmodule Incunabula.BookController do
  use Incunabula.Web, :controller

  plug :authenticate_user when action in [:index]

  def index(conn, _params) do
    books = Incunabula.Git.get_books()
    books2 = for %{title: t, slug: s} <- books, do: {t, s}
    render conn, "index.html",
    books: books2
  end

  def show(conn, %{"slug" => slug}) do
    render conn, "show.html",
      slug:  slug
  end

  def create(conn, %{"book" => book}) do
    %{"book_title" => book_title} = book
    case Incunabula.Git.create_book(book_title) do
      {:ok, slug} ->
        conn
        |> redirect(to: "/books/" <> slug)
      {:error, err} ->
        conn
        |> put_flash(:error, err)
        |> render("index.html")
    end
  end

end
