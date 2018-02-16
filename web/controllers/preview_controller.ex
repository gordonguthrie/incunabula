defmodule Incunabula.PreviewController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_user when action in [:show]

  def show(conn, %{"chapterslug" => ch_slug,
                   "slug"        => slug}, _user) do
    do_show(conn, slug, ch_slug, :chapter)
  end

  def show(conn, %{"chaffslug" => ch_slug,
                   "slug"      => slug}, _user) do
    do_show(conn, slug, ch_slug, :chaff)
  end

  defp do_show(conn, slug, ch_slug, type) do
    booksdir = Incunabula.Git.get_books_dir()
    preview_dir = case type do
                    :chapter -> "preview_html"
                    :summary -> "preview_html"
                    :chaff   -> "chaff_html"
                  end
    filename = case type do
                 :chapter -> ch_slug <> ".html"
                 :summary -> ch_slug <> ".summary.html"
                 :chaff   -> ch_slug <> ".html"
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
