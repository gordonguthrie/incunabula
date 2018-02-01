defmodule Incunabula.ChapterController do
  use Incunabula.Web, :controller

  def create(conn, %{"chapter" => chapter,
                     "slug"    => slug}) do
    %{"chapter_title" => chapter_title} = chapter
    :ok = Incunabula.Git.create_chapter(slug, chapter_title)
    conn
    |> redirect(to: Path.join("/books", slug))
  end

  def show(conn, %{"chapterslug" => chapterslug,
                   "slug"        => slug}) do
    IO.inspect chapterslug
    {:ok, booktitle} = Incunabula.Git.get_title(slug)
    {:ok, chaptertitle} = Incunabula.Git.get_chapter_title(slug, chapterslug)
    render conn, "show.html",
      title:        booktitle,
      chaptertitle: chaptertitle,
      slug:         slug
  end

end
