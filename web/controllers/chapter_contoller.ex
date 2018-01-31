defmodule Incunabula.ChapterController do
  use Incunabula.Web, :controller

  def create(conn, %{"chapter" => chapter,
                     "slug"    => slug}) do
    %{"chapter_title" => chapter_title} = chapter
    :ok = Incunabula.Git.create_chapter(slug, chapter_title)
    conn
    |> redirect(to: Path.join("/books", slug))
  end

end
