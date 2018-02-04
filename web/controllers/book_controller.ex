defmodule Incunabula.BookController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_user when action in [:index, :show, :create]

  def index(conn, _params, _user) do
    changeset = Incunabula.Book.changeset()
    render conn, "index.html",
      changeset: changeset
  end

  def show(conn, %{"slug"  => slug}, _user) do
    booktitle        = Incunabula.Git.get_book_title(slug)
    render conn, "show.html",
      slug:               slug,
      title:              booktitle,
      chapterchangeset:   Incunabula.Chapter.changeset(),
      imagechangeset:     Incunabula.Image.changeset(),
      newchaffchangeset:  Incunabula.Chaff.newchangeset(),
      copychaffchangeset: Incunabula.Chaff.copychangeset(),
      newchapter:         Path.join(["/books",  slug, "/chapter/new"]),
      newimage:           Path.join(["/books/", slug, "/image/new"]),
      newchaff:           Path.join(["/books",  slug, "chaff/new"]),
      copychaff:          Path.join(["/books",  slug, "chaff/copy"])
  end

  def create(conn, %{"book" => book} = params, user) do
    %{"book_title" => book_title} = book
    case Incunabula.Git.create_book(book_title, user) do
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
