defmodule Incunabula.Auth do
  import Plug.Conn
  import Phoenix.Controller

  def init([]) do
  end

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)
    put_current_user(conn, user_id)
  end

  def authenticate_reviewer(conn, _opts) do
    %{"slug"       => slug,
      "reviewslug" => reviewslug} = conn.params
    reviewer = Incunabula.Git.get_reviewer(slug, reviewslug)
    user = conn.assigns.current_user
    is_valid? = true
    case user do
      ^reviewer ->
        conn
        |> put_current_user(user)
      _other ->
        conn
        |> put_flash(:error, "You must be the reviewer to peform this action")
        |> redirect(to: "/")
        |> halt()
    end
  end

  def authenticate_author_or_reviewer(conn, _opts) do
    %{"slug" => slug} = conn.params
    author = Incunabula.Git.get_author(slug)
    reviewers = Incunabula.Git.get_raw_reviewers(slug)
    user = conn.assigns.current_user
    is_valid? = Enum.member?([author] ++ reviewers, user)
    case is_valid? do
      true ->
        conn
        |> put_current_user(user)
      false ->
        conn
        |> put_flash(:error, "You must be the author or a reviewer to peform this action")
        |> redirect(to: "/")
        |> halt()
    end
  end

  def authenticate_author(conn, opts) do
    %{"slug" => slug} = conn.params
    author = Incunabula.Git.get_author(slug)
    cond do
      user = conn.assigns.current_user ->
        case user do
          ^author ->
            conn
            |> put_current_user(user)
          _other ->
            conn
            |> put_flash(:error, "You must be the author to peform this action")
            |> redirect(to: "/")
            |> halt()
        end
    end
  end

  def authenticate_admin(conn, _opts) do
    cond do
      user = conn.assigns.current_user ->
        case user do
          "admin" ->
            conn
            |> put_current_user(user)
          _other ->
            conn
            |> put_flash(:error, "You must be admin to peform this action")
            |> redirect(to: "/")
            |> halt()
        end
      true ->
        conn
        |> put_flash(:error, "You must be logged in as admin to access that page")
        |> redirect(to: "/")
        |> halt()
    end
  end

  def authenticate_user(conn, _opts) do
    cond do
      user = conn.assigns.current_user ->
        conn
        |> put_current_user(user)
    true ->
        conn
        |> put_flash(:error, "You must be logged in to access that page")
        |> redirect(to: "/")
        |> halt()
    end
  end

  defp put_current_user(conn, user) do
    token = Phoenix.Token.sign(conn, "user socket", user)
    conn
    |> assign(:current_user, user)
    |> assign(:user_token, token)
  end

end
