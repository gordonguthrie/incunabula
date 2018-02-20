defmodule Incunabula.ReviewerController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_user when action in [
    :newreviewer,
    :removereviewer
  ]

  def newreviewer(conn, %{"new_reviewer" => new_reviewer,
                          "slug"         => slug}, user) do
    %{"username" => username} = new_reviewer
    case username do
      "admin" ->
        conn
        |> put_flash(:error, "don't use the admin account as a reviewer please")
        |> redirect(to: Path.join(["/books", slug, "#reviewing"]))
      _ ->
        case Incunabula.Git.add_reviewer(slug, username, user) do
          :ok ->
            conn
            |> redirect(to: Path.join(["/books", slug, "#reviewing"]))
          {:error, error} ->
            conn
            |> put_flash(:error, error)
            |> redirect(to: Path.join(["/books", slug, "#reviewing"]))
        end
    end
  end

  def removereviewer(conn, %{"reviewer" => reviewer,
                             "slug"        => slug}, user) do
    case Incunabula.Git.remove_reviewer(slug, reviewer, user) do
      :ok ->
        conn
        |> redirect(to: Path.join(["/books", slug, "#reviewing"]))
      {:error, error} ->
        conn
        |> put_flash(:error, error)
        |> redirect(to: Path.join(["/books", slug, "#reviewing"]))
    end
  end

end
