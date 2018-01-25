defmodule Incunabula.BookChannel do
  use Incunabula.Web, :channel

  def join("book:" <> bookslug, _params, socket) do
    IO.inspect "in BookChannel.join"
    IO.inspect bookslug
    :timer.send_interval(5_000, :ping)
    {:ok, assign(socket, :bookslug, bookslug)}
  end

  def handle_info(:ping, socket) do
    count = socket.assigns[:count] || 1
    IO.inspect "in handle info"
    IO.inspect count
    push socket, "ping", %{count: count}
    {:noreply, assign(socket, :count, count + 1)}
  end

end
