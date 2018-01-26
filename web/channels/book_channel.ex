defmodule Incunabula.BookChannel do
  use Incunabula.Web, :channel

  def join("book:" <> bookslug, _params, socket) do
    :timer.send_interval(5_000, :ping)
    {:ok, assign(socket, :bookslug, bookslug)}
  end

end
