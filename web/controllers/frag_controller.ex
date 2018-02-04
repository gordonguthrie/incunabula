defmodule Incunabula.FragController do
  use Incunabula.Web, :controller

  def get_chaffs(slug, chaffs) do
    conn = make_fresh_conn()
    make_html conn, "chaffs.html",
      slug:   slug,
      chaffs: chaffs
  end

  def get_chapters_dropdown(slug, chapters) do
    conn = make_fresh_conn()
    make_html conn, "chapters_dropdown.html",
      slug:               slug,
      chapters:           chapters
  end

  def get_chapters(slug, chapters) do
    conn = make_fresh_conn()
    make_html conn, "chapters.html",
      slug:     slug,
      chapters: chapters
  end

  def get_images(slug, images) do
    conn = make_fresh_conn()
    make_html conn, "images.html",
      slug:   slug,
      images: images
  end

  def get_books(books) do
    conn = make_fresh_conn()
    make_html conn, "books.html",
      books: books
  end

  defp make_html(conn, template, args) do
    response = render(conn, template, args)
    response.resp_body
  end

  defp make_fresh_conn() do
    # yeah, I am using a testing conn to do the rendering
    # 0800-BITE-ME.com
    _conn = Phoenix.ConnTest.build_conn()
    |> put_view(Incunabula.FragView)
  end

end
