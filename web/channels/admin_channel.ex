defmodule Incunabula.AdminChannel do
  use Incunabula.Web, :channel

  def join("admin:get_users", _params, socket) do
    users = IncunabulaUtilities.Users.get_users()
    html = Incunabula.FragController.get_users(users)
    {:ok, html, socket}
  end

  def join("admin:get_users_dropdown", _params, socket) do
    users = IncunabulaUtilities.Users.get_users()
    html = Incunabula.FragController.get_users_dropdown(users)
    {:ok, html, socket}
  end

end
