defmodule Incunabula.HelpController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  def index(conn, _params, _user) do
    render conn, "index.html",
    layout: {Incunabula.LayoutView, "blank.html"}
  end

end
