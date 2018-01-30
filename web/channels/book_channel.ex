defmodule Incunabula.BookChannel do
  use Incunabula.Web, :channel

  def join("book:" <> bookslug, _params, socket) do
    [component, book] = String.split(bookslug, ":")
    reply = get_reply(book, component)
    {:ok, reply, socket}
  end

  def get_reply(book, "get_contents") do
    contents = Incunabula.Git.get_contents(book)
    contents
  end

  def get_reply(book, "get_images") do
    images = Incunabula.Git.get_images(book)
    images
  end

end
