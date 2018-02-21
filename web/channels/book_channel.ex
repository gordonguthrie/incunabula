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

  def get_reply(:get_reviewers_dropdown, %{slug: slug}) do
    reviewers = Incunabula.Git.get_raw_reviewers(slug)
    _html = Incunabula.FragController.get_users_dropdown(reviewers)
  end

  def get_reply(:get_possible_reviewers_dropdown, %{slug: slug}) do
    users = IncunabulaUtilities.Users.get_users()
    reviewers = Incunabula.Git.get_raw_reviewers(slug)
    possiblereviewers = remove_reviewers_and_admin(users, reviewers)
    _html = Incunabula.FragController.get_users_dropdown(possiblereviewers)
  end

  def get_reply(:get_reviewers, %{slug: slug,
                                 role: role}) do
    _reviewers = Incunabula.Git.get_reviewers(slug, role)
  end

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

  def get_reply(:get_reviews, %{slug: slug,
                                role: role}) do
    _reviews = Incunabula.Git.get_reviews(slug, role)
  end

  def get_reply(:get_chaffs, %{slug: slug,
                               role: role}) do
    _chaff = Incunabula.Git.get_chaffs(slug, role)
  end

  def get_reply(:get_chapters, %{slug: slug,
                                 role: role}) do
    _chapters = Incunabula.Git.get_chapters(slug, role)
  end

  def get_reply(:get_images, %{slug: slug,
                               role: role}) do
    _images = Incunabula.Git.get_images(slug, role)
  end

  def get_reply(:update_chaff_title, %{slug:       _slug,
                                       chaff_slug: _chaff_slug}) do
    :ok
  end

  def get_reply(:update_chapter_title, %{slug:         _slug,
                                         chapter_slug: _chapter_slug}) do
    :ok
  end

  def get_reply(:update_book_title, %{slug: _slug}) do
    :ok
  end

  # this is a push channel so we only reply the current tag
  def get_reply(:save_review_edits, %{slug:       slug,
                                      reviewslug: _reviewslug}) do
    _current_tag_msg = Incunabula.Git.get_current_tag_msg(slug)
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

  def get_reply(:save_review_edits, topicparams, pushparams, user) do
    %{slug:       slug,
      reviewslug: reviewslug} = topicparams
    %{"commit_title" => commit_title,
      "commit_msg"   => commit_msg,
      "data"         => data,
      "tag_bump"     => tag_bump} = pushparams
    tag = Incunabula.Git.update_review(slug, reviewslug, commit_title,
      commit_msg, data, tag_bump, user)
    tag
  end

  def get_reply(:save_chapter_edits, topicparams, pushparams, user) do
    %{slug:        slug,
      chapterslug: chapterslug} = topicparams
    %{"commit_title" => commit_title,
      "commit_msg"   => commit_msg,
      "data"         => data,
      "tag_bump"     => tag_bump} = pushparams
      tag = Incunabula.Git.update_chapter(slug, chapterslug, commit_title,
        commit_msg, data, tag_bump, user)
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

  defp parse_route(["get_reviewers_dropdown", slug]) do
    {:get_reviewers_dropdown, %{slug: slug}}
  end

  defp parse_route(["get_possible_reviewers_dropdown", slug]) do
    {:get_possible_reviewers_dropdown, %{slug: slug}}
  end

  defp parse_route(["get_reviewers", slug, role]) do
    {:get_reviewers, %{slug: slug,
                       role: role}}
  end

  defp parse_route(["get_chapters_dropdown", slug]) do
    {:get_chapters_dropdown, %{slug: slug,}}
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

  defp parse_route(["get_chapters", slug, role]) do
    {:get_chapters, %{slug: slug,
                      role: role}}
  end

  defp parse_route(["get_chaffs", slug, role]) do
    {:get_chaffs, %{slug: slug,
                    role: role}}
  end

  defp parse_route(["get_reviews", slug, role]) do
    {:get_reviews, %{slug: slug,
                     role: role}}
  end

  defp parse_route(["get_images", slug, role]) do
    {:get_images, %{slug: slug,
                    role: role}}
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

  defp parse_route(["save_review_edits", slug, "review", reviewslug]) do
    {:save_review_edits, %{slug:       slug,
                           reviewslug: reviewslug}}
  end

  defp parse_route(["save_chaff_edits", slug, "chaff", chaffslug]) do
    {:save_chaff_edits, %{slug:      slug,
                          chaffslug: chaffslug}}
  end

  defp parse_route(["save_chapter_edits", slug, "chapter", chapterslug]) do
    {:save_chapter_edits, %{slug:        slug,
                            chapterslug: chapterslug}}
  end

  defp remove_reviewers_and_admin(users, reviewers) do
    # if you are already a reviewer (or if you are admin) we are gonnae wheech you out
   possible_reviewers = Enum.reduce(reviewers ++ ["admin"], users, fn(x, acc) -> List.delete(acc, x) end)
   Enum.sort(possible_reviewers)
  end

end
