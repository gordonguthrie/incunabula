defmodule Incunabula.PreviewController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_author_or_reviewer when action in [
    :show,
    :show_tag,
    :summary
  ]

  def show(conn, %{"reviewslug" => review_slug,
                   "slug"       => slug}, _user) do
    do_show(conn, slug, review_slug, :review)
  end

  def show(conn, %{"chaffslug" => chaff_slug,
                   "slug"      => slug}, _user) do
    do_show(conn, slug, chaff_slug, :chaff)
  end

  def show(conn, %{"chapterslug" => chapter_slug,
                   "slug"        => slug}, _user) do
    do_show(conn, slug, chapter_slug, :chapter)
  end

  def show_tag(conn, %{"chapterslug" => chapter_slug,
                       "slug"        => slug,
                       "tag"         => tag}, _user) do
    booksdir = Incunabula.Git.get_books_dir()
    file = Path.join([
      booksdir,
      slug,
      "preview_html",
      "tags",
      tag
    ])
    {:ok, binary} = File.read(file)
    conn
    |> put_resp_header("content-type", "image/png;")
    |> send_resp(200, binary)
  end

  defp do_show(conn, slug, frag_slug, type) do
    booksdir = Incunabula.Git.get_books_dir()
    preview_dir = case type do
                    :chapter -> "preview_html"
                    :review  -> "review_html"
                    :summary -> "preview_html"
                    :chaff   -> "chaff_html"
                  end
    filename = case type do
                 :chapter -> frag_slug <> ".html"
                 :review  -> frag_slug <> ".html"
                 :summary -> frag_slug <> ".summary.html"
                 :chaff   -> frag_slug <> ".html"
               end
    file = Path.join([
      booksdir,
      slug,
      preview_dir,
      filename
    ])
    {:ok, binary} = File.read(file)
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> send_resp(200, binary)
  end

  def summary(conn, %{"chapterslug" => ch_slug,
                      "slug"        => slug}, _user) do
    do_show(conn, slug, ch_slug, :summary)
  end

end
