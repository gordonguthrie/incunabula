defmodule Incunabula.HTMLController do
  use Incunabula.Web, :controller

  # there is no authentication because this is called from Incunabula.Git only
  def make_preview(title, author, body) do
    make_preview(title, author, body, "")
  end

  def make_preview(title, author, body, image) do
    conn = make_fresh_conn()
    args = %{title:  title,
             author: author,
             body:   body,
             image:  image}
    make_html conn, "preview.html", args
  end

  defp make_html(conn, template, args) do
    response = render(conn, template, args)
    response.resp_body
  end

  defp make_fresh_conn() do
    # yeah, I am using a testing conn to do the rendering
    # 0800-BITE-ME.com
    _conn = Phoenix.ConnTest.build_conn()
    |> put_view(Incunabula.HTMLView)
  end

end
