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
                   "copy"  => copy,
                   "slug"  => slug}, user) do
    %{"chapter_slug" => chapter_slug} = copy
    %{"chaff_title"  => chaff_title,
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

  def show(conn, %{"chaffslug" => chaffslug,
                   "slug"      => slug}, _user) do
    booktitle  = Incunabula.Git.get_book_title(slug)
    chafftitle = Incunabula.Git.get_chaff_title(slug, chaffslug)
    changeset  = Incunabula.SaveEdit.changeset()
    savepath   = Path.join(["/books", slug, "chaff", chaffslug, "save"])
    {_tag, contents} = Incunabula.Git.get_chaff(slug, chaffslug)
    render conn, "show.html",
      changeset:  changeset,
      title:      booktitle,
      chafftitle: chafftitle,
      chaffslug:  chaffslug,
      save_edits: savepath,
      contents:   contents,
      slug:       slug
  end

  def index(conn, _params, _user) do
    render conn, "index.html"
  end

end
