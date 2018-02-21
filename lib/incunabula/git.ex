defmodule Incunabula.Git do

  use GenServer

  @moduledoc """
  This gen server serves two seperate roles:
  * it is a point of serialisation which ensures that (subject to force majeur)
    actions from the front end are atomic
    * I write a file to disk
    * I prepare a commit in git
    * I execute the commit
    * I push the commit to GitHub
    Then, and only then does this server start working on your request
  * it subscribes to all the channels and sends them messages when things on disk change
  """

  #
  # Define the various files and directories
  #

  @chaptersDB  "chapters.db"
  @imagesDB    "images.db"
  @chaffDB     "chaff.db"
  @reviewsDB   "reviews.db"
  @reviewersDB "reviewers.db"

  @chaptersDir "chapters"
  @imagesDir   "images"
  @chaffDir    "chaff"
  @reviewsDir  "reviews"

  @preview_htmlDir "preview_html"
  @chaff_htmlDir   "chaff_html"
  @reviews_htmlDir "review_html"

  @title  "title.txt"
  @author "author.txt"

  @timeout 10_000

  require Logger

  #
  # API
  #

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, []}
  end

  def add_reviewer(slug, username, user) do
    GenServer.call(__MODULE__, {:add_reviewer, {slug, username, user}}, @timeout)
  end

  def remove_reviewer(slug, username, user) do
    GenServer.call(__MODULE__, {:remove_reviewer, {slug, username, user}}, @timeout)
  end

  def has_reviewers?(slug) do
    GenServer.call(__MODULE__, {:has_reviewers?, slug}, @timeout)
  end

  def has_chapters?(slug) do
    GenServer.call(__MODULE__, {:has_chapters?, slug}, @timeout)
  end

  def load_image(slug, image, user) do
   GenServer.call(__MODULE__, {:load_image, {slug, image, user}}, @timeout)
  end

  def copy_chapter_to_review(_slug, chapter, reviewer, _user)
  when chapter == "" or
    reviewer   == "" do
    {:error, "must specify a chapter to copy and a reviewer"}
  end

  def copy_chapter_to_review(slug, chapter_slug, reviewer, user) do
    GenServer.call(__MODULE__, {:copy_chapter_to_review,
                                {slug, chapter_slug, reviewer, user}}, @timeout)
  end

  def copy_chapter_to_chaff(_slug, _chapter_slug, "", _user) do
    {:error, "title cannot be blank"}
  end

  def copy_chapter_to_chaff(_slug, "", _chaff_title, _user) do
    {:error, "must specify a chapter to copy"}
  end

  def copy_chapter_to_chaff(slug, chapter_slug, chaff_title, user) do
    GenServer.call(__MODULE__, {:copy_chapter_to_chaff,
                                {slug, chapter_slug, chaff_title, user}},
      @timeout)
  end

  def create_chaff(_slug, "", _user) do
    {:error, "title cannot be blank"}
  end

  def create_chaff(slug, chaff_title, user) do
    GenServer.call(__MODULE__, {:create, {:chaff, slug, chaff_title, user}},
      @timeout)
  end

  def create_chapter(_slug, "", _user) do
    {:error, "title cannot be blank"}
  end

  def create_chapter(slug, chapter_title, user) do
    GenServer.call(__MODULE__, {:create, {:chapter, slug, chapter_title, user}},
      @timeout)
  end

  def update_chapter_order(slug, new_chapters, user) do
    GenServer.call(__MODULE__, {:update_chapter_order,
                                {slug, new_chapters, user}}, @timeout)
  end

  def update_chaff_title(slug, chaff_slug, new_title, user) do
    GenServer.call(__MODULE__, {:update_title, {:chaff, slug, chaff_slug,
                                                new_title, user}}, @timeout)
  end

  def update_chapter_title(slug, chapter_slug, new_title, user) do
    GenServer.call(__MODULE__, {:update_title, {:chapter, slug, chapter_slug,
                                                new_title, user}}, @timeout)
  end

  def update_book_title(slug, new_title, user) do
    GenServer.call(__MODULE__, {:update_book_title, {slug, new_title, user}},
      @timeout)
  end

  def update_chapter(slug, chapter_slug, commit_title,
    commit_msg, data, tag_bump, user) do
    GenServer.call(__MODULE__, {:update_chapter, {slug, chapter_slug,
                                                  commit_title, commit_msg,
                                                  data, tag_bump, user}},
      @timeout)
  end

  def update_review(slug, review_slug, commit_title,
    commit_msg, data, tag_bump, user) do
    GenServer.call(__MODULE__, {:update_review, {slug, review_slug,
                                                 commit_title, commit_msg,
                                                 data, tag_bump, user}},
      @timeout)
  end

  def update_chaff(slug, chaff_slug, commit_title,
    commit_msg, data, tag_bump, user) do
    GenServer.call(__MODULE__, {:update_chaff, {slug, chaff_slug,
                                                commit_title, commit_msg,
                                                data, tag_bump, user}},
      @timeout)
  end

  def create_book("", _author) do
    {:error, "title cannot be blank"}
  end

  def create_book(book_title, author) do
    # bump the timeout as creating a book can take a while server side
    GenServer.call(__MODULE__, {:create_book, {book_title, author}}, @timeout)
  end

  def get_author(slug) do
    GenServer.call(__MODULE__, {:get_author, slug}, @timeout)
  end


  def get_history(slug) do
    GenServer.call(__MODULE__, {:get_history, slug}, @timeout)
  end

  def get_chapters_dropdown(slug) do
    GenServer.call(__MODULE__, {:get_chapters_dropdown, slug}, @timeout)
  end

  def get_current_tag_msg(slug) do
    GenServer.call(__MODULE__, {:get_tag_msg, slug}, @timeout)
  end

  def get_books() do
    GenServer.call(__MODULE__, :get_books, @timeout)
  end

  # this call doesn't need to be serialised as it is not under git
  def get_books_dir() do
    _dir = Path.join(get_env(:root_directory), "books")
  end

  def get_book_title(slug) do
    GenServer.call(__MODULE__, {:get_book_title, slug}, @timeout)
  end

  def get_raw_reviewers(slug) do
    GenServer.call(__MODULE__, {:get_reviewers, :raw, slug}, @timeout)
  end

  def get_reviewer(slug, reviewslug) do
    GenServer.call(__MODULE__, {:get_reviewer, slug, reviewslug}, @timeout)
  end

  def get_reviewers(slug) do
    GenServer.call(__MODULE__, {:get_reviewers, :html, slug}, @timeout)
  end

  def get_review(slug, reviewslug) do
    GenServer.call(__MODULE__, {:get_review, {slug, reviewslug}}, @timeout)
  end

  def get_chaff(slug, chaffslug) do
    GenServer.call(__MODULE__, {:get_chaff, {slug, chaffslug}}, @timeout)
  end

  def get_chapter(slug, chapterslug) do
    GenServer.call(__MODULE__, {:get_chapter, {slug, chapterslug}},
      @timeout)
  end

  def get_review_title(slug, reviewslug) do
    GenServer.call(__MODULE__, {:get_review_title, {slug, reviewslug}},
      @timeout)
  end

  def get_chaff_title(slug, chaffslug) do
    GenServer.call(__MODULE__, {:get_chaff_title, {slug, chaffslug}}, @timeout)
  end

  def get_chapter_title(slug, chapterslug) do
    GenServer.call(__MODULE__, {:get_chapter_title, {slug, chapterslug}},
      @timeout)
  end

  def get_reviews(slug) do
    GenServer.call(__MODULE__, {:get, {:reviews, slug}}, @timeout)
  end

  def get_chaffs(slug) do
    GenServer.call(__MODULE__, {:get, {:chaffs, slug}}, @timeout)
  end

  def get_chapters_json(slug) do
    GenServer.call(__MODULE__, {:get_chapters_json, slug}, @timeout)
  end

  def get_chapters(slug) do
    GenServer.call(__MODULE__, {:get, {:chapters, slug}}, @timeout)
  end

  def get_images(slug) do
    GenServer.call(__MODULE__, {:get, {:images, slug}}, @timeout)
  end

  @doc "a shell command to check that the github token and stuff is correct"
  def check_github_SHELL_ONLY() do
    githubPAT = get_env(:personal_access_token)
    args = [
      "-i",
      "-H",
      "Authorization: token " <> githubPAT,
      "https://api.github.com/user/repos"
    ]
    {page, _} = System.cmd("curl", args, [])
    outputfile = "/tmp/incunabula.check_github.html"
    :ok = File.write(outputfile, page)
    IO.inspect ""
    IO.inspect "Output written to " <> outputfile
    :ok
  end

  #
  # call backs
  #

  def handle_call(call, _from, state) do
    reply = case call do
              {:get_author, slug} ->
                do_get_author(slug)

              {:get_history, slug} ->
                do_get_history(slug)

              {:add_reviewer,  {slug, username, user}} ->
                do_add_reviewer(slug, username, user)

              {:remove_reviewer,  {slug, username, user}} ->
                do_remove_reviewer(slug, username, user)

              {:has_reviewers?,   slug} ->
                has(@reviewersDB, slug)

              {:has_chapters?,   slug} ->
                has(@chaptersDB, slug)

              {:load_image,  {slug, image, user}} ->
                do_load_image(slug, image, user)

              {:copy_chapter_to_review,  {slug, chapter_slug, reviewer, user}} ->
                do_copy_chapter_to_review(slug, chapter_slug, reviewer, user)

              {:copy_chapter_to_chaff,  {slug, chapter_slug, chaff_title, user}} ->
                do_copy_chapter_to_chaff(slug, chapter_slug, chaff_title, user)

              {:create,  {type, slug, chapter_title, user}} ->
                do_create(type, slug, chapter_title, user)

              {:update_chapter_order,  {slug, new_chapters, user}} ->
                do_update_chapter_order(slug, new_chapters, user)

              {:update_title,  {type, slug, ch_slug, new_title, user}} ->
                do_update_title(type, slug, ch_slug, new_title, user)

              {:update_book_title,  {slug, new_title, user}} ->
                do_update_book_title(slug, new_title, user)

              {:update_review,  {slug, review_slug, commit_title, commit_msg, data, tag_bump, user}} ->
                do_update_review(slug, review_slug, commit_title, commit_msg, data, tag_bump, user)

              {:update_chaff,  {slug, chaff_slug, commit_title, commit_msg, data, tag_bump, user}} ->
                do_update_chaff(slug, chaff_slug, commit_title, commit_msg, data, tag_bump, user)

              {:update_chapter,  {slug, chapter_slug, commit_title, commit_msg, data, tag_bump, user}} ->
                do_update_chapter(slug, chapter_slug, commit_title, commit_msg, data, tag_bump, user)

              {:create_book,  {book_title, author}} ->
                do_create_book(book_title, author)

              {:get_tag_msg, slug} ->
                do_get_tag_msg(get_book_dir(slug))

              {:get_book_title, slug} ->
                {:ok, title} = read_file(get_book_dir(slug), @title)
                title

              {:get_chapters_dropdown, slug} ->
                do_get_chapters_dropdown(slug)

              {:get_reviewer, slug, reviewslug} ->
                do_get_reviewer(slug, reviewslug)

              {:get_reviewers, format, slug} ->
                do_get_reviewers(format, slug)

              {:get_review, {slug, reviewslug}} ->
                do_get_text(slug, :review, reviewslug)

              {:get_chaff, {slug, chaffslug}} ->
                do_get_text(slug, :chaff, chaffslug)

              {:get_chapter, {slug, chapterslug}} ->
                do_get_text(slug, :chapter, chapterslug)

              {:get_review_title, {slug, reviewslug}} ->
                do_get_review_title(slug, reviewslug)

              {:get_chaff_title, {slug, chaffslug}} ->
                do_get_chaff_title(slug, chaffslug)

              {:get_chapter_title, {slug, chapterslug}} ->
                do_get_chapter_title(slug, chapterslug)

              {:get_chapters_json, slug} ->
                do_get_chapters_json(slug)

              {:get, {type, slug}} ->
                do_get(type, slug)

              :get_books ->
                do_get_books()

              {:read, {slug, file}} ->
                read_file(get_book_dir(slug), file)

            end
    {:reply, reply, state}
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

  defp do_get_author(slug) do
    bookdir = get_book_dir(slug)
    {:ok, author} = read_file(bookdir, @author)
    author
  end

  defp do_get_history(slug) do
    bookdir = get_book_dir(slug)
    args = [
      "tag",
      "-n"
    ]
    {rawhistory, 0} = System.cmd("git", args, [cd: bookdir])
    process_raw_history(rawhistory)
  end

  defp process_raw_history(rawhistory) do
    lines = String.split(rawhistory, "\n")
    newlines = for l <- lines, do: process_line(l)
    parsed_lines = Enum.reverse(Enum.sort(newlines))
    for {{npub, nrel, nmajor, nminor}, msg} <- parsed_lines do
      %{version: %{publication: npub,
                   release:     nrel,
                   major:       nmajor,
                   minor:       nminor},
        msg: msg}
    end
  end

  defp process_line(""), do: ""

  defp process_line(line) do
    [publication, release, major | rest] = String.split(line, ".")
    newrest = Enum.join(rest, ".")
    [minor | newrest2] = String.split(newrest, " ")
    newrest3 = String.strip(Enum.join(newrest2, " "))
    npub   = String.to_integer(publication)
    nrel   = String.to_integer(release)
    nmajor = String.to_integer(major)
    nminor = String.to_integer(minor)
    {{npub, nrel, nmajor, nminor}, newrest3}
  end

  defp do_add_reviewer(slug, username, user) do
    bookdir = get_book_dir(slug)
    # only add the user if they are not allready a reviewer
    case IncunabulaUtilities.DB.lookup_value(bookdir, @reviewersDB, :reviewer, username, :reviewer) do
      {:error, :no_match_of_key} ->
        newrecord = new_reviewers_record(username)
        {:ok, title}  = read_file(get_book_dir(slug), @title)
        tag = make_tag("add reviewer", title, slug, user, "adding " <> username)
        bookdir
        |> IncunabulaUtilities.DB.appendDB(@reviewersDB, newrecord)
        |> add_to_git(:all)
        |> commit_to_git(tag)
        |> bump_tag(tag, "major", user)
        |> push_to_github(slug)
        |> push_to_channel(slug, slug, "book:get_reviewers:")
        :ok
      _ ->
        {:error, "reviewer already added"}
    end
  end

  defp do_remove_reviewer(slug, username, user) do
    bookdir = get_book_dir(slug)
    case IncunabulaUtilities.DB.lookup_value(bookdir, @reviewersDB, :reviewer, username, :reviewer) do
      {:ok, _username} ->
        {:ok, title}  = read_file(get_book_dir(slug), @title)
        tag = make_tag("remove reviewer", title, slug, user, "removing " <> username)
        bookdir
        |> IncunabulaUtilities.DB.delete_records(@reviewersDB, :reviewer, username)
        |> add_to_git(:all)
        |> commit_to_git(tag)
        |> bump_tag(tag, "major", user)
        |> push_to_github(slug)
        |> push_to_channel(slug, slug, "book:get_reviewers:")
        :ok
      {:error, :no_match_of_key} ->
        {:error, "not a reviewer"}
    end
  end

  defp do_load_image(slug, %{"image_title"    => image_title,
                             "uploaded_image" => uploaded_image}, user) do
    %Plug.Upload{filename: filename,
                 path:     tmp_image_path} = uploaded_image
    ext = String.downcase(Path.extname(filename))
    imagename = image_title <> ext
    shortimageslug = Incunabula.Slug.to_slug(image_title)
    imageslug = shortimageslug <> ext
    bookdir = get_book_dir(slug)
    commitmsg = "upload new image: " <> imagename <>
      " - " <> imageslug <> " by " <> user
    # we might upload 'something.png' with the title of 'bobby dazzler'
    # and then later upload 'anotherthing.jpg' also with the title
    # of 'bobby dazzler' - this would result in files called
    # 'bobby-dazzler.png' and 'bobby-dazzler.jpg' but with the same
    # slug of 'bobby-dazzler' so lets check for any 'bobby-dazzler.*'
    wildcard = Path.join([bookdir, @imagesDir, shortimageslug <> ".*"])
    case Path.wildcard(wildcard) do
      [] ->
        imagedetails = get_image_details(tmp_image_path)
        newimage = %{title:         image_title,
                     original_name: filename,
                     image_slug:    shortimageslug,
                     image_details: imagedetails,
                     extension:     ext}
        bookdir
        |> copy_image(imageslug, tmp_image_path)
        |> IncunabulaUtilities.DB.appendDB(@imagesDB, newimage)
        |> add_to_git(:all)
        |> commit_to_git(commitmsg)
        |> bump_tag("new image loaded " <> imageslug, "major", user)
        |> push_to_github(slug)
        |> push_to_channel(slug, slug, "book:get_images:")
        :ok
      _ ->
        {:error, shortimageslug <> ".* already exists"}
    end
  end

  defp copy_image(dir, titleslug, tmp_image_path) do
    path = Path.join(dir, @imagesDir)
    to   = Path.join(path, titleslug)
    :ok = File.mkdir_p(path)
    :ok = File.cp(tmp_image_path, to)
    dir
  end

  defp do_update_chapter_order(slug, new_chapters, user) do
    bookdir = get_book_dir(slug)
    {:ok, title}  = read_file(get_book_dir(slug), @title)
    commit_msg = "reorder chapters"
    tag = make_tag(commit_msg, title, slug, user, "")
    bookdir
    |> IncunabulaUtilities.DB.replaceDB(@chaptersDB, new_chapters)
    |> add_to_git(:all)
    |> commit_to_git(commit_msg)
    |> bump_tag(tag, "major", user)
    |> push_to_github(slug)
    |> push_to_channel(slug, slug, "book:get_chapters:")
    |> push_to_channel(slug, slug, "book:get_chapters_dropdown:")
    :ok
  end

  defp do_update_title(type, slug, ch_slug, new_title, user) do
    bookdir = get_book_dir(slug)
    {oldtitle,
     prefix,
     msg,
     topic,
     keyfield,
     updatefield,
     db} = case type do
             :chapter -> {do_get_chapter_title(slug, ch_slug),
                         "edit chapter title",
                         "new chapter title",
                         "book:get_chapter_title:" <> slug
                         <> ":chapter:" <> ch_slug,
                         :chapter_slug, :chapter_title, @chaptersDB}
             :chaff   -> {do_get_chaff_title(slug, ch_slug),
                         "edit chaff title",
                         "new chaff title",
                         "book:get_chaff_title:" <> slug
                         <> ":chaff:" <> ch_slug,
                         :chaff_slug, :chaff_title, @chaffDB}
                end
    case new_title do
      ^oldtitle ->
        # do nothing
        :ok
      _ ->
        commitmsg = "old title was " <> oldtitle <> "new title is "
        <> new_title <> "(" <> ch_slug  <> ")"
        tag = make_tag(prefix, new_title, slug, user, msg)
        bookdir
        |> IncunabulaUtilities.DB.update_value(db, keyfield, ch_slug,
        updatefield, new_title)
        |> add_to_git(:all)
        |> commit_to_git(commitmsg)
        |> bump_tag(tag, "major", user)
        |> push_to_github(slug)
        |> push_to_channel2(topic, new_title)
        :ok
    end
  end

  defp do_update_book_title(slug, new_title, user) do
    bookdir = get_book_dir(slug)
    {:ok, oldtitle} = read_file(get_book_dir(slug), @title)
    commitmsg = "old title was " <> oldtitle <> "new title is "
    <> new_title <> "(" <> slug <> ")"
    tag = make_tag("edit book title", new_title, slug, user, "new book title ")
    bookdir
    |> write_to_file(@title, new_title)
    |> add_to_git(:all)
    |> commit_to_git(commitmsg)
    |> bump_tag(tag, "major", user)
    |> push_to_github(slug)
    |> push_to_channel("books:list")
    |> push_to_channel(slug, slug, "book:get_book_title:")
    :ok
  end

  defp do_update_review(slug, review_slug, commit_title, commit_msg,
    data, tag_bump, user) do
    bookdir  = get_book_dir(slug)
    review_title =  do_get_review_title(slug, review_slug)
    tag = make_tag("update review", review_title, review_slug,
      user, commit_title)
    review = review_slug <> ".eider"
    route  = make_route([slug, "review", review_slug])
    # the user may have pressed save without making any changes
    # so we write the data, check if there is any change
    # and then, and only then, retag etc
    bookdir
    |> write_to_file(@reviewsDir, review, data)
    case nothing_to_commit?(bookdir) do
      true ->
        msg = "no changes to save: " <> tag
        :ok = direct_push_to_channel(route,
          "book:save_review_edits:", msg)
        msg
      false ->
        bookdir
        |> add_to_git(:all)
        |> make_html(:review, review_title, review_slug, user)
        |> commit_to_git(commit_msg)
        |> bump_tag(tag, tag_bump, user)
        |> push_to_github(slug)
        |> push_to_channel(slug, route, "book:save_review_edits:")
        |> do_get_tag_msg()
    end
  end

  defp do_update_chaff(slug, ch_slug, commit_title, commit_msg,
    data, tag_bump, user) do
    bookdir  = get_book_dir(slug)
    ch_title = do_get_chaff_title(slug, ch_slug)
    tag      = make_tag("update chaff", ch_title, ch_slug, user, commit_title)
    chaff    = ch_slug <> ".eider"
    route    = make_route([slug, "chaff", ch_slug])
    # the user may have pressed save without making any changes
    # so we write the data, check if there is any change
    # and then, and only then, retag etc
    bookdir
    |> write_to_file(@chaffDir, chaff, data)
    case nothing_to_commit?(bookdir) do
      true ->
        msg = "no changes to save: " <> do_get_tag_msg(bookdir)
        :ok = direct_push_to_channel(route, "book:save_chaff_edits:", msg)
        msg
      false ->
        bookdir
        |> make_html(:chaff, ch_title, ch_slug, user)
        |> add_to_git(:all)
        |> commit_to_git(commit_msg)
        |> bump_tag(tag, tag_bump, user)
        |> push_to_github(slug)
        |> push_to_channel(slug, route, "book:save_chaff_edits:")
        |> do_get_tag_msg()
    end
  end

  defp do_update_chapter(slug, ch_slug, commit_title, commit_msg,
    data, tag_bump, user) do
    bookdir  = get_book_dir(slug)
    ch_title = do_get_chapter_title(slug, ch_slug)
    tag      = make_tag("update chapter", ch_title, ch_slug, user, commit_title)
    chapter  = ch_slug <> ".eider"
    route    = make_route([slug, "chapter", ch_slug])
    # the user may have pressed save without making any changes
    # so we write the data, check if there is any change
    # and then, and only then, retag etc
    bookdir
    |> write_to_file(@chaptersDir, chapter, data)
    case nothing_to_commit?(bookdir) do
      true ->
        msg = "no changes to save: " <> do_get_tag_msg(bookdir)
        :ok = direct_push_to_channel(route, "book:save_chapter_edits:", msg)
        msg
      false ->
        bookdir
        |> make_html(:chapter, ch_title, ch_slug, user)
        |> add_to_git(:all)
        |> commit_to_git(commit_msg)
        |> bump_tag(tag, tag_bump, user)
        |> push_to_github(slug)
        |> push_to_channel(slug, route, "book:save_chapter_edits:")
        |> do_get_tag_msg()
    end
  end

  defp do_copy_chapter_to_review(slug, chapter_slug, reviewer, user) do
    bookdir       = get_book_dir(slug)
    chapter_title = do_get_chapter_title(slug, chapter_slug)
    currenttag    = get_current_tag(bookdir)
    review_title  = chapter_title <> " " <> currenttag
    review_slug = Incunabula.Slug.to_slug(review_title)
    from    = Path.join([bookdir, @chaptersDir, chapter_slug <> ".eider"])
    to_path = Path.join([bookdir, @reviewsDir])
    to      = Path.join([to_path,  review_slug  <> ".eider"])

    case File.exists?(to) do
      false ->
        :ok = File.mkdir_p(to_path)
        {:ok, _} = File.copy(from, to)
        prefix = review_slug <> " copied from " <> chapter_slug
        newrecord = new_review_record(review_title, reviewer, chapter_slug, currenttag)
        msg = "initial creation of " <> slug <> " assgined to " <> reviewer
        tag = make_tag(prefix, review_title, slug, user, msg)
        bookdir
        |> add_to_git(:all)
        |> push_to_github(slug)
        |> bump_tag(msg, "major", user)
        |> make_html(:review, review_title, review_slug, user)
        |> IncunabulaUtilities.DB.appendDB(@reviewsDB, newrecord)
        |> push_to_github(slug)
        |> push_to_channel(slug, slug, "book:get_reviews:")
        :ok
      true ->
        # gotta switch back to master anyhoo
        {:error, review_slug <> " already exists"}
    end
  end

  defp do_copy_chapter_to_chaff(slug, chapter_slug, chaff_title, user) do
    chaff_slug = Incunabula.Slug.to_slug(chaff_title)
    bookdir = get_book_dir(slug)
    from = Path.join([bookdir, @chaptersDir, chapter_slug <> ".eider"])
    to   = Path.join([bookdir, @chaffDir,    chaff_slug   <> ".eider"])
    case File.exists?(to) do
      false ->
        {:ok, _} = File.copy(from, to)
        prefix = chaff_slug <> " copied from " <> chapter_slug
        tag = make_tag(prefix, chaff_title, chaff_slug, user)
        currenttag = get_current_tag(bookdir)
        msg = prefix <> " at " <> currenttag
        newrecord = new_chaff_record(chaff_title, msg)
        bookdir
        |> IncunabulaUtilities.DB.appendDB(@chaffDB, newrecord)
        |> add_to_git(:all)
        |> make_html(:chaff, chaff_title, chaff_slug, user)
        |> commit_to_git(tag)
        |> bump_tag(tag, "major", user)
        |> push_to_github(slug)
        |> push_to_channel(slug, slug, "book:get_chaffs:")
        :ok
      true ->
        {:error, chaff_slug <> " already exists"}
    end
  end

  defp do_create(type, slug, title, user) do
    title_slug = Incunabula.Slug.to_slug(title)
    bookdir = get_book_dir(slug)
    subdir = case type do
               :chapter -> @chaptersDir
               :chaff   -> @chaffDir
               :review  -> @reviewsDir
             end
    dir  = Path.join([bookdir, subdir])
    file = title_slug <> ".eider"
    case File.exists?(file) do
      false ->
        ^dir = write_to_file(dir, file, [])
        # creating a new chapter is a banal event
        # so we just reuse the tag for the commit msg
        prefix = case type do
                   :chapter -> "create new chapter"
                   :chaff   -> "create new chaff"
                 end
        channel = case type do
                    :chapter -> "book:get_chapters:"
                    :chaff   -> "book:get_chaffs:"
                  end
        tag = make_tag(prefix, title, title_slug, user)
        {db, newrecord} = case type do
                            :chapter ->
                              newr = new_chapter_record(title)
                              {@chaptersDB, newr}
                            :chaff ->
                              msg = "de novo at " <> tag
                              newr = new_chaff_record(title, msg)
                              {@chaffDB, newr}
                          end
        bookdir
        |> IncunabulaUtilities.DB.appendDB(db, newrecord)
        |> add_to_git(:all)
        |> make_html(type, title, title_slug, user)
        |> commit_to_git(tag)
        |> bump_tag(tag, "major", user)
        |> push_to_github(slug)
        |> push_to_channel(slug, slug, channel)
        case type == :chapter do
          true ->
            bookdir
            |> push_to_channel(slug, slug, "book:get_chapters:")
            |> push_to_channel(slug, slug, "book:get_chapters_dropdown:")
            :ok
          false ->
            :ok
        end
      true ->
        {:error, title <> " already exists"}
    end
  end

  defp get_image_details(image_path) do
    args = [
      image_path
    ]
    details = System.cmd("file", args)
    :lists.flatten(:io_lib.format("~p", [details]))
  end

  defp do_create_book(book_title, author) do
    slug = Incunabula.Slug.to_slug(book_title)
    bookdir = get_book_dir(slug)
    case File.exists?(bookdir) do
      false ->
        :ok = create_repo_on_github(slug)
        bookdir
        |> make_dir
        |> do_git_init
        |> write_to_file(@title,       book_title)
        |> write_to_file(@author,      author)
        |> write_to_file(".gitignore", standard_gitignore())
        |> IncunabulaUtilities.DB.createDB(@chaptersDB)
        |> IncunabulaUtilities.DB.createDB(@imagesDB)
        |> IncunabulaUtilities.DB.createDB(@chaffDB)
        |> IncunabulaUtilities.DB.createDB(@reviewsDB)
        |> IncunabulaUtilities.DB.createDB(@reviewersDB)
        |> add_to_git(:all)
        |> commit_to_git("basic setup of directory")
        |> tag_git(0, 0, 1, 1, "initial creation of " <> slug, author)
        |> push_to_github(slug, :without_tags) # don't want tags on first create
        |> push_to_channel("books:list")
        {:ok, slug}
      true ->
        {:error, "The book " <> slug <> " exists already"}
    end
  end

  defp do_get_tag_msg(dir) do
    tag = get_current_tag(dir)
    args = [
      "show",
      tag
    ]
    {msg, 0} = System.cmd("git", args, [cd: dir])
    tag <> " - " <> parse_commit_msg(msg)
  end

  defp get_current_tag(dir) do
    args = [
      "describe",
      "--tags",
      "--abbrev=0"
    ]
    {tag, 0} = System.cmd("git", args, [cd: dir])
    String.strip(tag)
  end

  defp do_get_chapters_dropdown(slug) do
    chapters  = IncunabulaUtilities.DB.getDB(get_book_dir(slug), @chaptersDB)
    _dropdown = Incunabula.FragController.get_chapters_dropdown(slug, chapters)
  end

  defp do_get_reviewer(slug, reviewslug) do
    {:ok, reviewer} = IncunabulaUtilities.DB.lookup_value(get_book_dir(slug),
      @reviewsDB, :review_slug, reviewslug, :reviewer)
    reviewer
  end

  defp do_get_reviewers(format, slug) do
    reviewers = IncunabulaUtilities.DB.getDB(get_book_dir(slug), @reviewersDB)
    case format do
      :html ->
        _html = Incunabula.FragController.get_reviewers(reviewers, slug)
      :raw ->
        for %{reviewer: r} <- reviewers, do: r
    end
  end

  defp do_get_text(slug, type, textslug) do
    bookdir = get_book_dir(slug)
    tag = do_get_tag_msg(bookdir)
    path = case type do
             :chapter -> Path.join([get_book_dir(slug), @chaptersDir])
             :chaff   -> Path.join([get_book_dir(slug), @chaffDir])
             :review  -> Path.join([get_book_dir(slug), @reviewsDir])
           end
    {:ok, contents} = read_file(path, textslug <> ".eider")
    {tag, contents}
  end

  defp do_get_review_title(slug, reviewslug) do
    dir = get_book_dir(slug)
    {:ok, title} = IncunabulaUtilities.DB.lookup_value(dir, @reviewsDB,
      :review_slug, reviewslug, :review_title)
    title
  end

  defp do_get_chaff_title(slug, chaffslug) do
    dir = get_book_dir(slug)
    {:ok, title} = IncunabulaUtilities.DB.lookup_value(dir, @chaffDB,
      :chaff_slug, chaffslug, :chaff_title)
    title
  end

  defp do_get_chapter_title(slug, chapterslug) do
    dir = get_book_dir(slug)
    {:ok, title} = IncunabulaUtilities.DB.lookup_value(dir, @chaptersDB,
      :chapter_slug, chapterslug, :chapter_title)
    title
  end

  defp do_get_chapters_json(slug) do
    _chapters = IncunabulaUtilities.DB.getDB(get_book_dir(slug), @chaptersDB)
  end

  defp do_get(:reviews, slug) do
    reviews = IncunabulaUtilities.DB.getDB(get_book_dir(slug), @reviewsDB)
    _html   = Incunabula.FragController.get_reviews(slug, reviews)
  end

  defp do_get(:chaffs, slug) do
    chaffs = IncunabulaUtilities.DB.getDB(get_book_dir(slug), @chaffDB)
    _html  = Incunabula.FragController.get_chaffs(slug, chaffs)
  end

  defp do_get(:chapters, slug) do
    chapters = IncunabulaUtilities.DB.getDB(get_book_dir(slug), @chaptersDB)
    reviews  = IncunabulaUtilities.DB.getDB(get_book_dir(slug), @reviewsDB)
    marked   = mark_review_status(chapters, reviews, [])
    _html    = Incunabula.FragController.get_chapters(slug, marked)
  end

  defp do_get(:images, slug) do
    images = IncunabulaUtilities.DB.getDB(get_book_dir(slug), @imagesDB)
    _html  = Incunabula.FragController.get_images(slug, images)
  end

  defp mark_review_status([], _, acc), do: Enum.reverse(acc)

  defp mark_review_status([h | t], reviews, acc) do
    chapter_slug = Map.get(h, :chapter_slug)
    review_status = get_status(reviews, chapter_slug, :unlocked)
    newacc = Map.put(h, :status, review_status)
    mark_review_status(t, reviews, [newacc| acc])
  end

  defp get_status([], _chapter_slug, acc), do: acc

  defp get_status([h | t], chapter_slug, acc) do
    case Map.get(h, :chapter_slug) do
      ^chapter_slug ->
        status = Map.get(h, :review_status)
        case status do
          "review closed" -> get_status(t, chapter_slug, acc)
          _               -> :locked
        end
      _other -> get_status(t, chapter_slug, acc)
    end
  end

  defp do_get_books() do
    dir = get_books_dir()
    case File.ls(dir) do
      {:ok, files} ->
        get_books(dir, files)
      {:error, reason} ->
        Logger.error "listings books in " <> dir <> " fails because: "
        <> Atom.to_string(reason)
        []
    end
  end

  defp get_books(rootdir, files) do
    subs  = for f <- files, File.dir?(Path.join([rootdir, f])), do: f
    slugs = for d <- subs,  File.dir?(Path.join([rootdir, d, "/.git"])), do: d
    books = for s <- slugs,
      {:ok, t} = File.read(Path.join([rootdir, s, @title])) do
        {t, s}
    end
    Incunabula.FragController.get_books(Enum.sort(books))
  end

  defp get_env(key) do
    configs = Application.get_env(:incunabula, :configuration)
    configs[key]
  end

  defp create_repo_on_github(reponame) do
    githubPAT = get_env(:personal_access_token)
    {_status, json} = Poison.encode(%{"name" => reponame})
    args = [
      "-i",
      "-H",
      "Authorization: token "  <> githubPAT,
      "https://api.github.com/user/repos",
      "-d",
      json
    ]
    # Bit shit check of return values
    # Rly should be an http request but hey
    #{_, 0} = System.cmd("curl", args)
    :ok
  end

  defp make_dir(dir) do
    :ok = File.mkdir(dir)
    dir
  end

  defp add_to_git(dir, :all) do
    cmd = "git"
    args = [
      "add",
      "--all"
    ]
    {"", 0} = System.cmd(cmd, args, [cd: dir])
    dir
  end

  defp commit_to_git(dir, msg) do
    cmd = "git"
    args = [
      "commit",
      "-m",
      msg
    ]
    {_return, 0} = System.cmd(cmd, args, [cd: dir])
    dir
  end

  defp bump_tag(dir, msg, type, person) when type == "major"
  or type == "minor"
  or type == "release"
  or type == "publication" do
    tag = get_current_tag(dir)
    [i, j, k, l] = String.split(tag, ".")
    {publication, release, major, minor}
    = case type do
        "publication" ->
          newi = to_string(String.to_integer(i) + 1)
          {newi, 0, 0, 0}
        "release" ->
          newj = to_string(String.to_integer(j) + 1)
          {i, newj, 0, 0}
        "major" ->
          newk = to_string(String.to_integer(k) + 1)
          {i, j, newk, "0"}
        "minor" ->
          newl = to_string(String.to_integer(l) + 1)
          {i, j, k, newl}
      end
    tag_git(dir, publication, release, major, minor, msg, person)
    dir
  end

  defp tag_git(dir, publication, release, major, minor, msg, person) do
    args = [
      "tag",
      "-a",
      to_string(publication) <> "." <> to_string(release) <> "." <>
        to_string(major) <> "." <> to_string(minor),
      "-m",
      msg <> "\ncommited by " <> person
    ]
    {"", 0} = System.cmd("git", args, [cd: dir])
    dir
  end

  # we usually want tags (except for book creation)
  defp push_to_github(dir, repo) do
    push_to_github(dir, repo, :with_tags)
  end

  defp push_to_github(dir, repo, type) when type == :with_tags
  or type == :without_tags do
    cmd = "git"
    github_account = get_env(:github_account)
    githubPAT = get_env(:personal_access_token)
    url = Path.join([
      "https://" <> githubPAT <> "@github.com",
      github_account,
      repo <> ".git"
    ])
    args = case type do
             :with_tags ->
               [
                 "push",
                 "--repo=" <> url,
                 "--tags"
               ]
             :without_tags ->
               [
                 "push",
                 "--repo=" <> url,
               ]
           end
    # {"", return} = System.cmd(cmd, args, [cd: dir])
    dir
  end

  defp push_to_channel2(dir, topic, msg) do
    # No I don't understand why the event and the message associated with it
    # have to be called books neither
    Incunabula.Endpoint.broadcast topic, "books", %{books: msg}
    dir
  end

  defp push_to_channel(dir, "books:list") do
    response = do_get_books()
    Incunabula.Endpoint.broadcast "books:list", "books", %{books: response}
    dir
  end

  defp push_to_channel(dir, slug, route, topic) do
    response = case topic do
                 "books:list" ->
                   do_get_books()

                   "book:get_book_title:" ->
                   {:ok, title} = read_file(get_book_dir(slug), @title)
                   title

                   "book:get_reviewers:" ->
                   do_get_reviewers(:html, slug)

                   "book:get_reviews:" ->
                   do_get(:reviews, slug)

                   "book:get_chaffs:" ->
                   do_get(:chaffs, slug)

                   "book:get_chapters_dropdown:" ->
                   do_get(:chapters, slug)

                   "book:get_chapters:" ->
                   do_get(:chapters, slug)

                   "book:get_images:" ->
                   do_get(:images, slug)

                   "book:save_review_edits:" ->
                   do_get_tag_msg(get_book_dir(slug))

                   "book:save_chaff_edits:" ->
                   do_get_tag_msg(get_book_dir(slug))

                   "book:save_chapter_edits:"  ->
                   do_get_tag_msg(get_book_dir(slug))

      end
    Incunabula.Endpoint.broadcast topic <> route, "books", %{books: response}
    dir
  end

  defp direct_push_to_channel(route, type, msg) when
  type == "book:save_review_edits:"  or
  type == "book:save_chaff_edits:"   or
  type == "book:save_chapter_edits:" do
    # No I don't understand why the event and the message associated with it
    # have to be called books neither
    Incunabula.Endpoint.broadcast type <> route,
      "books", %{books: msg}
    :ok
  end

  defp do_git_init(dir) do
    return = System.cmd("git", ["init"], cd: dir)
    # force a crash if this failed
    {<<"Initialised empty Git repository in">> <> _rest, _} = return
    dir
  end

  # you need to be able to build a root dir in a pipeline
  # to ensure the directory exists
  defp write_to_file(dir, subdir, file, data) do
    rootdir = Path.join([dir, subdir])
    write_to_file(rootdir, file, data)
  end

  defp write_to_file(dir, file, data) do
    path = Path.join([dir, file])
    :ok = File.mkdir_p(dir)
    :ok = File.write(path, data)
    dir
  end

  def read_file(dir, file) do
    File.read(Path.join([dir, file]))
  end

  defp standard_gitignore() do
    "lock.file"
  end

  defp get_book_dir(slug) do
    Path.join(get_books_dir(), slug)
  end

  defp log(dir, msg) do
    IO.inspect "********************"
    IO.inspect ""
    IO.inspect msg
    IO.inspect ""
    IO.inspect "********************"
    dir
  end

  defp parse_commit_msg(string) do
    lines = String.split(string, "\n")
    fetch(lines, 2) <> " - " <> fetch(lines, 4)
  end

  defp fetch(list, index) when is_list(list) and is_integer(index) do
    {:ok, val} = Enum.fetch(list, index)
    val
  end

  defp make_tag(prefix, title, slug, user) do
    make_tag(prefix, title, slug, user, "")
  end

  defp make_tag(prefix, title, slug, user, msg) do
    Enum.join([prefix, title, "(" <> slug <> ")", "by", user, msg], " - ")
  end

  defp nothing_to_commit?(dir) do
    args = [
      "status"
    ]
    {reply, 0} = System.cmd("git", args, [cd: dir])
    split = String.split(reply, "\n")
    case split do
      [
        "On branch " <> _rest,
       "nothing to commit, working directory clean",
        ""
      ]                                              -> true
      _                                              -> false
    end
  end

  defp make_html(dir, type, title, slug, user)
  when type == :chapter
  or   type == :review do
    {sourcedir, outputdir} = case type do
                               :chapter -> {@chaptersDir, @preview_htmlDir}
                               :review  -> {@reviewsDir,  @reviews_htmlDir}
                             end
    eiderdownfile = Path.join([dir, sourcedir, slug <> ".eider"])
    {:ok, eiderdown} = File.read(eiderdownfile)

    htmldir     = Path.join([dir, outputdir])
    webpage     = slug <> ".html"
    summarypage = slug <> ".summary.html"

    eiderdown_charlist = to_charlist(eiderdown)

    # first we make the preview
    body = to_string(:eiderdown.to_html_from_utf8(eiderdown_charlist))
    html = Incunabula.HTMLController.make_preview(title, user, body)
    ^htmldir = write_to_file(htmldir, webpage, html)

    # now we make the summary
    sum = to_string(:eiderdown.to_summary_from_utf8(eiderdown_charlist))
    s_html = Incunabula.HTMLController.make_preview(title, user, sum)
    ^htmldir = write_to_file(htmldir, summarypage, s_html)

    dir
  end

  defp make_html(dir, :chaff, chaff_title, chaff_slug, user) do
    eiderdownfile = Path.join([dir, @chaffDir,      chaff_slug <> ".eider"])
    {:ok, eiderdown} = File.read(eiderdownfile)

    htmldir = Path.join([dir, @chaff_htmlDir])
    webpage = chaff_slug <> ".html"
    body = to_string(:eiderdown.to_html_from_utf8(to_charlist(eiderdown)))
    html = Incunabula.ChaffHTMLController.make_preview(chaff_title, user, body)
    ^htmldir = write_to_file(htmldir, webpage, html)
    dir
  end

  defp make_route(list) do
    Enum.join(list, ":")
  end

#  defp checkout_branch(dir, branch) do
#    args = [
#      "checkout",
#      to_string(branch)
#    ]
#    {_, 0} = System.cmd("git", args, [cd: dir])
#    # return dir to pipe
#    dir
#  end

  defp new_chapter_record(title) do
    slug = Incunabula.Slug.to_slug(title)
    %{chapter_slug: slug,
      chapter_title: title}
  end

  defp new_chaff_record(title, creation) do
    slug = Incunabula.Slug.to_slug(title)
    %{chaff_slug:  slug,
      chaff_title: title,
      creation:    creation}
  end

  defp new_reviewers_record(username) do
    %{reviewer: username}
  end

  defp new_review_record(title, reviewer, chapter_slug, tag) do
    slug = Incunabula.Slug.to_slug(title)
    %{review_slug:   slug,
      reviewer:      reviewer,
      review_title:  title,
      chapter_slug:  chapter_slug,
      tag:           tag,
      review_status: "in review"}
  end

  defp has(db, slug) do
    records = IncunabulaUtilities.DB.getDB(get_book_dir(slug), db)
    _reply  = case records do
                [] -> false
                _  -> true
              end
  end

end
