defmodule Incunabula.BooksChannel do
  use Incunabula.Web, :channel

  def join("books:list", _params, socket) do
    :timer.send_interval(5_000, :ping)
    books = Incunabula.Git.get_books()
    {:ok, books, socket}
  end

  def handle_in(msg, params, socket) do
    {:noreply, socket}
  end

  def handle_info(:ping, socket) do
    count = socket.assigns[:count] || 1
    push socket, "ping", %{count: count}
    {:noreply, assign(socket, :count, count + 1)}
  end

  # this clause handles an info message we get sent when we render HTML
  # for the message channel via a controller/view
  def handle_info({:plug_conn, :sent}, socket) do
    {:noreply, socket}
  end

  # this clause handles an info message we get sent when we render HTML
  # for the message channel via a controller/view
  def handle_info({ref, {200, _, _}}, socket) when is_reference(ref) do
    {:noreply, socket}
  end

end
