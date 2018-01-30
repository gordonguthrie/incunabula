defmodule Incunabula.FragController do
  use Incunabula.Web, :controller

  def get_contents(contents) do
    conn = make_fresh_conn()
    make_html conn, "contents.html",
      contents: contents
  end

  def get_images(images) do
    conn = make_fresh_conn()
    make_html conn, "images.html",
      images: images
  end


  def get_books(books) do
    conn = make_fresh_conn()
    make_html conn, "books.html",
      books: books
  end

  def make_html(conn, template, args) do
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
