defmodule Incunabula.BookChannel do
  use Incunabula.Web, :channel

  def join("book:" <> bookslug, _params, socket) do
    {route, topicparams} = parse_topic(bookslug)
    reply = get_reply(route, topicparams)
    {:ok, reply, socket}
  end

  def handle_in("book:" <> bookslug, pushparams, socket) do
    {route, topicparams} = parse_topic(bookslug)
    reply = get_reply(route, topicparams, pushparams)
    {:reply, :ok, socket}
  end

  @doc "get_reply/2 is the reply on joining"
  def get_reply(:get_book_title, %{slug: slug}) do
    _title = Incunabula.Git.get_book_title(slug)
  end

  def get_reply(:get_chapters, %{slug: slug}) do
    _chapters = Incunabula.Git.get_chapters(slug)
  end

  def get_reply(:get_images, %{slug: slug}) do
    _images = Incunabula.Git.get_images(slug)
  end

  # this is a push channel so we only reply the current tag
  def get_reply(:save_edits, %{slug:        slug,
                               chapterslug: _chapterslug}) do
    _current_tag_msg = Incunabula.Git.get_current_tag_msg(slug)
  end

  @doc "get_reply/3 is the reply on a push request"
  def get_reply(:save_edits, topicparams, pushparams) do
    %{slug:        slug,
      chapterslug: chapterslug} = topicparams
    IO.inspect "in get_reply for save_edits"
    IO.inspect pushparams
    %{"commit_title" => commit_title,
      "commit_msg"   => commit_msg,
      "data"         => data,
      "tag_bump"     => tag_bump} = pushparams
      tag = Incunabula.Git.update_chapter(slug, chapterslug, commit_title,
        commit_msg, data, tag_bump, "General Franco")
      IO.inspect tag
      tag
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
