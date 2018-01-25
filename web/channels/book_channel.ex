defmodule Incunabula.BookChannel do
  use Incunabula.Web, :channel

  def join("book:" <> bookslug, _params, socket) do
    IO.inspect "in BookChannel.join"
    IO.inspect bookslug
    {:ok, assign(socket, :bookslug, bookslug)}
  end

end
