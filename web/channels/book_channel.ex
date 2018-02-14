defmodule Incunabula.BookChannel do
  use Incunabula.Web, :channel

  def join("book:" <> bookslug, _params, socket) do
    {route, topicparams} = parse_topic(bookslug)
    reply = get_reply(route, topicparams)
    {:ok, reply, socket}
  end

  def handle_in("book:" <> bookslug, pushparams, socket) do
    %Phoenix.Socket{assigns: %{user_id: user}} = socket
    {route, topicparams} = parse_topic(bookslug)
    reply = get_reply(route, topicparams, pushparams, user)
    {:reply, {:ok, %{books: reply}}, socket}
  end

  @doc "get_reply/2 is the reply on joining"
  def get_reply(:get_chapters_dropdown, %{slug: slug}) do
    _dropdown = Incunabula.Git.get_chapters_dropdown(slug)
  end

  def get_reply(:get_chaff_title, %{slug:       slug,
                                    chaff_slug: chaff_slug}) do
    _title = Incunabula.Git.get_chaff_title(slug, chaff_slug)
  end

  def get_reply(:get_chapter_title, %{slug:         slug,
                                      chapter_slug: chapter_slug}) do
    _title = Incunabula.Git.get_chapter_title(slug, chapter_slug)
  end

  def get_reply(:get_book_title, %{slug: slug}) do
    _title = Incunabula.Git.get_book_title(slug)
  end

  def get_reply(:get_reviews, %{slug: slug}) do
    chaff = Incunabula.Git.get_reviews(slug)
  end

  def get_reply(:get_chaffs, %{slug: slug}) do
    chaff = Incunabula.Git.get_chaffs(slug)
  end

  def get_reply(:get_chapters, %{slug: slug}) do
    _chapters = Incunabula.Git.get_chapters(slug)
  end

  def get_reply(:get_images, %{slug: slug}) do
    _images = Incunabula.Git.get_images(slug)
  end

  def get_reply(:update_chaff_title, %{slug:       slug,
                                       chaff_slug: chaff_slug}) do
    :okchaff
  end

  def get_reply(:update_chapter_title, %{slug:         slug,
                                         chapter_slug: chapter_slug}) do
    :okchapter
  end

  def get_reply(:update_book_title, %{slug: slug}) do
    :ok
  end

  # this is a push channel so we only reply the current tag
  def get_reply(:save_chapter_edits, %{slug:        slug,
                                       chapterslug: _chapterslug}) do
    _current_tag_msg = Incunabula.Git.get_current_tag_msg(slug)
  end

   # this is a push channel so we only reply the current tag
  def get_reply(:save_chaff_edits, %{slug:      slug,
                                     chaffslug: _chaffslug}) do
    _current_tag_msg = Incunabula.Git.get_current_tag_msg(slug)
  end

  # handle in messages

  def get_reply(:update_chaff_title, topicparams, pushparams, user) do
    %{slug:       slug,
      chaff_slug: chaff_slug} = topicparams
    %{"field" => new_title}= pushparams
    :ok = Incunabula.Git.update_chaff_title(slug, chaff_slug, new_title, user)
  end

  def get_reply(:update_chapter_title, topicparams, pushparams, user) do
    %{slug:         slug,
      chapter_slug: chapter_slug} = topicparams
    %{"field" => new_title}= pushparams
    :ok = Incunabula.Git.update_chapter_title(slug, chapter_slug,
      new_title, user)
  end

    def get_reply(:update_book_title, topicparams, pushparams, user) do
    %{slug: slug} = topicparams
    %{"field" => new_title}= pushparams
    :ok = Incunabula.Git.update_book_title(slug, new_title, user)
  end

  def get_reply(:save_chapter_edits, topicparams, pushparams, user) do
    %{slug:        slug,
      chapterslug: chapterslug} = topicparams
    %{"commit_title" => commit_title,
      "commit_msg"   => commit_msg,
      "data"         => data,
      "tag_bump"     => tag_bump} = pushparams
      tag = Incunabula.Git.update_chapter(slug, chapterslug, commit_title,
        commit_msg, data, tag_bump, user, :master)
      tag
  end

  def get_reply(:save_chaff_edits, topicparams, pushparams, user) do
    %{slug:      slug,
      chaffslug: chaffslug} = topicparams
    %{"commit_title" => commit_title,
      "commit_msg"   => commit_msg,
      "data"         => data,
      "tag_bump"     => tag_bump} = pushparams
      tag = Incunabula.Git.update_chaff(slug, chaffslug, commit_title,
      commit_msg, data, tag_bump, user)
      tag
  end

  defp parse_topic(topic) do
    route = String.split(topic, ":")
    parse_route(route)
  end

  defp parse_route(["get_chapters_dropdown", slug]) do
    {:get_chapters_dropdown, %{slug: slug}}
  end

  defp parse_route(["get_chaff_title", slug, "chaff", chaff_slug]) do
    {:get_chaff_title, %{slug:       slug,
                         chaff_slug: chaff_slug}}
  end

  defp parse_route(["get_chapter_title", slug, "chapter", chapter_slug]) do
    {:get_chapter_title, %{slug:         slug,
                           chapter_slug: chapter_slug}}
  end

  defp parse_route(["get_book_title", slug]) do
    {:get_book_title, %{slug: slug}}
  end

  defp parse_route(["get_chapters", slug]) do
    {:get_chapters, %{slug: slug}}
  end

  defp parse_route(["get_chaffs", slug]) do
    {:get_chaffs, %{slug: slug}}
  end

  defp parse_route(["get_chaffs", slug]) do
    {:get_chaffs, %{slug: slug}}
  end

  defp parse_route(["get_reviews", slug]) do
    {:get_reviews, %{slug: slug}}
  end

  defp parse_route(["get_images", slug]) do
    {:get_images, %{slug: slug}}
  end

  defp parse_route(["update_chaff_title", slug, "chaff", chaff_slug]) do
    {:update_chaff_title, %{slug:       slug,
                            chaff_slug: chaff_slug}}
  end

  defp parse_route(["update_chapter_title", slug, "chapter", chapter_slug]) do
    {:update_chapter_title, %{slug:         slug,
                              chapter_slug: chapter_slug}}
  end

  defp parse_route(["update_book_title", slug]) do
    {:update_book_title, %{slug: slug}}
  end

  defp parse_route(["save_chaff_edits", slug, "chaff", chaffslug]) do
    {:save_chaff_edits, %{slug:      slug,
                          chaffslug: chaffslug}}
  end

  defp parse_route(["save_chapter_edits", slug, "chapter", chapterslug]) do
    {:save_chapter_edits, %{slug:        slug,
                            chapterslug: chapterslug}}
  end

end
