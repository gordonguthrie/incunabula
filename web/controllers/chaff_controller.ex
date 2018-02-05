defmodule Incunabula.ChaffController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_user when action in [:index, :new, :copy, :show]

  def new(conn, %{"chaff" => chaff,
                  "slug"  => slug}, user) do
    %{"chaff_title" => chaff_title,
      "copy?"       => "false"} = chaff
    case Incunabula.Git.create_chaff(slug, chaff_title, user) do
      :ok ->
        conn
        |> redirect(to: Path.join(["/books", slug, "#chaff"]))
      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> redirect(to: Path.join(["/books", slug, "#chaff"]))
    end
  end

  def copy(conn, %{"chaff" => chaff,
                   "slug"  => slug}, user) do
    %{"chaff_title"  => chaff_title,
      "chapter_slug" => chapter_slug,
      "copy?"        => "true"} = chaff
    case Incunabula.Git.copy_chapter_to_chaff(slug, chapter_slug, chaff_title, user) do
      :ok ->
        conn
        |> redirect(to: Path.join(["/books", slug, "#chaff"]))
      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> redirect(to: Path.join(["/books", slug, "#chaff"]))
    end
  end

  def show(conn, %{"chaffslug" => chaff_slug,
                   "slug"      => slug}, user) do
    conn
    |> redirect(to: Path.join(["/books", slug, "#chaff"]))
  end


  def index(conn, _params, _user) do
    render conn, "index.html"
  end
end
