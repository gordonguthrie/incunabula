defmodule Incunabula.BookController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_user               when action in [:index, :create]
  plug :authenticate_author_or_reviewer when action in [ :show, :history ]

  def index(conn, _params, _user) do
    changeset = Incunabula.Book.changeset()
    render conn, "index.html",
      changeset: changeset
  end

  def show(conn, %{"slug"  => slug}, _user) do
    booktitle      = Incunabula.Git.get_book_title(slug)
    has_chapters?  = Incunabula.Git.has_chapters?(slug)
    has_reviewers? = Incunabula.Git.has_reviewers?(slug)
    render conn, "show.html",
      slug:                slug,
      title:               booktitle,
      chapterchangeset:    Incunabula.Chapter.changeset(),
      imagechangeset:      Incunabula.Image.changeset(),
      newchaffchangeset:   Incunabula.Chaff.newchangeset(),
      copychaffchangeset:  Incunabula.Chaff.copychangeset(),
      copyreviewchangeset: Incunabula.Review.copychangeset(),
      reviewerchangeset:   Incunabula.Reviewer.changeset(),
      newchapter:          Path.join(["/books", slug, "chapter/new"]),
      newimage:            Path.join(["/books", slug, "image/new"]),
      newchaff:            Path.join(["/books", slug, "chaff/new"]),
      copychaff:           Path.join(["/books", slug, "chaff/copy"]),
      copyreview:          Path.join(["/books", slug, "review/copy"]),
      newreviewer:         Path.join(["/books", slug, "newreviewer"]),
      has_chapters:        has_chapters?,
      has_reviewers:       has_reviewers?
  end

  def create(conn, %{"book" => book}, user) do
    %{"book_title" => book_title} = book
    case Incunabula.Git.create_book(book_title, user) do
      {:ok, slug} ->
        conn
        |> redirect(to: "/books/" <> slug)
      {:error, err} ->
        changeset = Incunabula.Book.changeset()
        conn
        |> put_flash(:error, err)
        |> render("index.html", [changeset: changeset])
    end
  end

  def history(conn, %{"slug" => slug}, user) do
    history   = Incunabula.Git.get_history(slug)
    booktitle = Incunabula.Git.get_book_title(slug)
    render conn, "history.html",
      bookslug:    slug,
      booktitle:   booktitle,
      history:     history
  end

end
