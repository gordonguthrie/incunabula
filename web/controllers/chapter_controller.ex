defmodule Incunabula.ChapterController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_author when action in [:create, :delete, :show]

  def delete(conn, %{"chapterslug" => chapterslug,
                     "slug"        => slug}, user) do
    :ok = Incunabula.Git.delete_chapter(slug, chapterslug, user)
    conn
    |> redirect(to: Path.join("/books", slug))
  end

  def create(conn, %{"chapter" => chapter,
                     "slug"    => slug}, user) do
    %{"chapter_title" => chapter_title} = chapter
    case Incunabula.Git.create_chapter(slug, chapter_title, user) do
      :ok ->
        conn
        |> redirect(to: Path.join("/books", slug))
      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> redirect(to: Path.join(["/books", slug]))
    end
  end

  def show(conn, %{"chapterslug" => chapterslug,
                   "slug"        => slug}, _user) do
    booktitle    = Incunabula.Git.get_book_title(slug)
    chaptertitle = Incunabula.Git.get_chapter_title(slug, chapterslug)
    changeset    = Incunabula.SaveEdit.changeset()
    savepath     = Path.join(["/books", slug, "chapters", chapterslug, "save"])
    {_tag, contents} = Incunabula.Git.get_chapter(slug, chapterslug)
    render conn, "show.html",
      changeset:    changeset,
      title:        booktitle,
      chaptertitle: chaptertitle,
      chapterslug:  chapterslug,
      save_edits:   savepath,
      contents:     contents,
      slug:         slug
  end

end
