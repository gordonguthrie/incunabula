defmodule Incunabula.ReviewController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_user when action in [:index, :copy, :show]

  def copy(conn, %{"copy" => review,
                   "slug" => slug}, user) do
    %{"chapter_slug" => chapter_slug} = review
    case Incunabula.Git.copy_chapter_to_review(slug, chapter_slug, user) do
      :ok ->
        conn
        |> redirect(to: Path.join(["/books", slug, "#reviews"]))
      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> redirect(to: Path.join(["/books", slug, "#reviews"]))
    end
  end

  def show(conn, %{"reviewslug" => reviewslug,
                   "slug"       => slug}, user) do
    booktitle  = Incunabula.Git.get_book_title(slug)
    reviewtitle = Incunabula.Git.get_review_title(slug, reviewslug)
    changeset  = Incunabula.SaveEdit.changeset()
    savepath   = Path.join(["/books", slug, "review", reviewslug, "save"])
    {_tag, contents} = Incunabula.Git.get_review(slug, reviewslug)
    render conn, "show.html",
      changeset:   changeset,
      title:       booktitle,
      reviewtitle: reviewtitle,
      reviewslug:  reviewslug,
      save_edits:  savepath,
      contents:    contents,
      slug:        slug
  end

  def index(conn, _params, _user) do
    render conn, "index.html"
  end

end
