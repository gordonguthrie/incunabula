defmodule Incunabula.ChaffController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_user when action in [:index]

  def new(conn, %{"chaff" => chaff,
                  "slug"  => slug}, user) do
    %{"chaff_title" => chaff_title,
      "copy?"       => "false"} = chaff
    :ok = Incunabula.Git.create_chaff(slug, chaff_title, user)
    conn
    |> redirect(to: Path.join(["/books", slug, "#chaff"]))
  end

  def copy(conn, %{"chaff" => chaff,
                   "slug"  => slug}, user) do
    %{"chapter_title" => chapter_title,
      "copy?"         => "true"} = chaff
    IO.inspect "in chaff copy"
    IO.inspect chaff
    conn
    |> redirect(to: Path.join(["/books", slug, "#chaff"]))
  end

  def index(conn, _params, _user) do
    render conn, "index.html"
  end
end
