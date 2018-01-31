defmodule Incunabula.BookController do
  use Incunabula.Web, :controller

  plug :authenticate_user when action in [:index]

  def index(conn, _params) do
    changeset = Incunabula.Book.changeset()
    render conn, "index.html",
      changeset: changeset
  end

  def show(conn, %{"slug"  => slug}) do
    {:ok, title} = Incunabula.Git.get_title(slug)
    chapterchangeset = Incunabula.Chapter.changeset()
    imagechangeset   = Incunabula.Image.changeset()
    render conn, "show.html",
      slug:             slug,
      title:            title,
      chapterchangeset: chapterchangeset,
      imagechangeset:   imagechangeset,
      newchapter:       "/book/" <> slug <> "/chapter/new",
      newimage:         "/book/" <> slug <> "/image/new"
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
