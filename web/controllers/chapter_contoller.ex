defmodule Incunabula.ChapterController do
  use Incunabula.Web, :controller

  def create(conn, %{"chapter" => chapter,
                     "slug"    => slug} = params) do
    IO.inspect params
    %{"chapter_title" => chapter_title} = chapter
    :ok = Incunabula.Git.create_chapter(slug, chapter_title)
    conn
    |> redirect(to: Path.join("/books", slug))
  end

  def show(conn, %{"chapterslug" => chapterslug,
                   "slug"        => slug}) do
    IO.inspect chapterslug
    booktitle    = Incunabula.Git.get_book_title(slug)
    chaptertitle = Incunabula.Git.get_chapter_title(slug, chapterslug)
    changeset    = Incunabula.SaveEdit.changeset()
    savepath     = Path.join(["/books", slug, "chapters", chapterslug, "save"])
    render conn, "show.html",
      changeset:    changeset,
      title:        booktitle,
      chaptertitle: chaptertitle,
      chapterslug:  chapterslug,
      save_edits:   savepath,
      slug:         slug
  end

end
