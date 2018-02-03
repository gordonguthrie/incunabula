defmodule Incunabula.ChaffController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_user when action in [:index]

  def index(conn, _params, _user) do
    render conn, "index.html"
  end
end
