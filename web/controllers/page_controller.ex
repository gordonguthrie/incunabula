defmodule Incunabula.PageController do
  use Incunabula.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
