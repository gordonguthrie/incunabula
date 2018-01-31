defmodule Incunabula.BooksChannel do
  use Incunabula.Web, :channel

  def join("books:list", _params, socket) do
    :timer.send_interval(5_000, :ping)
    books = Incunabula.Git.get_books()
    {:ok, books, socket}
  end

  def handle_info(:ping, socket) do
    count = socket.assigns[:count] || 1
    push socket, "ping", %{count: count}
    {:noreply, assign(socket, :count, count + 1)}
  end

end
