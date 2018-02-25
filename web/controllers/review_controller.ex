defmodule Incunabula.ReviewController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_author when action in [
    :copy,
    :reconcile
  ]

  plug :authenticate_author_or_reviewer when action in [
    :index,
    :change_status
  ]

  plug :authenticate_reviewer when action in [
    :show,
  ]

  def reconcile(conn, params, _user) do
    %{"reviewslug" => reviewslug,
      "slug"       => slug} = params
    {reviewtag,   reviewtext}   = Incunabula.Git.get_review(slug, reviewslug)
    {originaltag, originaltext} = Incunabula.Git.get_original_from_review(slug,
      reviewslug)
    reconciliation = Incunabula.Reconcile.reconcile(slug, originaltext,
      reviewtext)
    render conn, "reconcile.html",
    reconciliation: reconciliation

  end

  def copy(conn, %{"copy"         => review,
                   "new_reviewer" => newreviewer,
                   "slug"         => slug}, user) do
    %{"chapter_slug" => chapter_slug} = review
    %{"username" => reviewer} = newreviewer
    case Incunabula.Git.copy_chapter_to_review(slug, chapter_slug, reviewer, user) do
      :ok ->
        conn
        |> redirect(to: Path.join(["/books", slug, "#reviewing"]))
      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> redirect(to: Path.join(["/books", slug, "#reviewing"]))
    end
  end

  def show(conn, %{"reviewslug" => reviewslug,
                   "slug"       => slug}, _user) do
    booktitle   = Incunabula.Git.get_book_title(slug)
    reviewtitle = Incunabula.Git.get_review_title(slug, reviewslug)
    changeset   = Incunabula.SaveEdit.changeset()
    savepath    = Path.join(["/books", slug, "review", reviewslug, "save"])
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

  def change_status(conn, params, user) do
    %{"newstatus"  => newstatus,
      "slug"       => slug,
      "reviewslug" => reviewslug} = params
    :ok = Incunabula.Git.update_review_status(slug, reviewslug, newstatus, user)
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_resp(200, "ok")
    end

end
