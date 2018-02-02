defmodule Incunabula.BookChannel do
  use Incunabula.Web, :channel

  def join("book:" <> bookslug, _params, socket) do
    {route, topicparams} = parse_topic(bookslug)
    reply = get_reply(route, topicparams)
    {:ok, reply, socket}
  end

  def handle_in(topic, params, socket) do
    IO.inspect topic
    IO.inspect params
    {:reply, :ok, socket}
  end

  def get_reply(:get_book_title, %{slug: slug}) do
    title = Incunabula.Git.get_book_title(slug)
    title
  end

  def get_reply(:get_chapters, %{slug: slug}) do
    chapters = Incunabula.Git.get_chapters(slug)
    chapters
  end

  def get_reply(:get_images, %{slug: slug}) do
    images = Incunabula.Git.get_images(slug)
    images
  end

  # this is a push channel so we only reply :ok on it
  def get_reply(:save_edits, %{slug:        slug,
                               chapterslug: chapterslug}) do
    :ok
  end

  defp parse_topic(topic) do
    route = String.split(topic, ":")
    parse_route(route)
  end

  defp parse_route(["get_book_title", slug]) do
    {:get_book_title, %{slug: slug}}
  end

  defp parse_route(["get_chapters", slug]) do
    {:get_chapters, %{slug: slug}}
  end

  defp parse_route(["get_images", slug]) do
    {:get_images, %{slug: slug}}
  end

  defp parse_route([slug, "chapter", chapterslug, "save_edits"]) do
    {:save_edits, %{slug:        slug,
                    chapterslug: chapterslug}}
  end

end
