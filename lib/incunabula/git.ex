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

  def has_chapters?(slug) do
    GenServer.call(__MODULE__, {:has_chapters?, slug})
  end

  def load_image(slug, image, user) do
   GenServer.call(__MODULE__, {:load_image, {slug, image, user}})
  end

  def copy_chapter_to_chaff(_slug, _chapter_slug, "", _user) do
    {:error, "title cannot be blank"}
  end

  def copy_chapter_to_chaff(_slug, "", _chaff_title, _user) do
    {:error, "must specify a chapter to copy"}
  end

  def copy_chapter_to_chaff(slug, chapter_slug, chaff_title, user) do
   GenServer.call(__MODULE__, {:copy_chapter_to_chaff, {slug, chapter_slug, chaff_title, user}})
  end

  def create_chaff(_slug, "", _user) do
    {:error, "title cannot be blank"}
  end

  def create_chaff(slug, chaff_title, user) do
    GenServer.call(__MODULE__, {:create, {:chaff, slug, chaff_title, user}})
  end

  def create_chapter(_slug, "", _user) do
    {:error, "title cannot be blank"}
  end

  def create_chapter(slug, chapter_title, user) do
    GenServer.call(__MODULE__, {:create, {:chapter, slug, chapter_title, user}})
  end

  def update_book_title(slug, new_title, user) do
    GenServer.call(__MODULE__, {:update_book_title, {slug, new_title, user}})
  end

  def update_chapter(slug, chapter_slug, commit_title,
    commit_msg, data, tag_bump, user) do
    GenServer.call(__MODULE__, {:update_chapter, {slug, chapter_slug,
                                                  commit_title, commit_msg,
                                                  data, tag_bump, user}})
  end

  def update_chaff(slug, chaff_slug, commit_title,
    commit_msg, data, tag_bump, user) do
    GenServer.call(__MODULE__, {:update_chaff, {slug, chaff_slug,
                                                   commit_title, commit_msg,
                                                   data, tag_bump, user}})
  end

  def create_book("", _author) do
    {:error, "title cannot be blank"}
  end

  def create_book(book_title, author) do
    GenServer.call(__MODULE__, {:create_book, {book_title, author}})
  end

  def get_chapters_dropdown(slug) do
    GenServer.call(__MODULE__, {:get_chapters_dropdown, slug})
  end

  def get_current_tag_msg(slug) do
    GenServer.call(__MODULE__, {:get_current_tag_msg, slug})
  end

  def get_books() do
    GenServer.call(__MODULE__, :get_books)
  end

  def get_books_dir() do
    _dir = Path.join(get_env(:root_directory), "books")
  end

  def get_book_title(slug) do
    GenServer.call(__MODULE__, {:get_book_title, slug})
  end

  def get_chaff(slug, chaffslug) do
    GenServer.call(__MODULE__, {:get_chaff, {slug, chaffslug}})
  end

  def get_chapter(slug, chapterslug) do
    GenServer.call(__MODULE__, {:get_chapter, {slug, chapterslug}})
  end

  def get_chaff_title(slug, chaffslug) do
    GenServer.call(__MODULE__, {:get_chaff_title, {slug, chaffslug}})
  end

  def get_chapter_title(slug, chapterslug) do
    GenServer.call(__MODULE__, {:get_chapter_title, {slug, chapterslug}})
  end

  def get_chaffs(slug) do
    GenServer.call(__MODULE__, {:get, {:chaffs, slug}})
  end

  def get_chapters(slug) do
    GenServer.call(__MODULE__, {:get, {:chapters, slug}})
  end

  def get_images(slug) do
    GenServer.call(__MODULE__, {:get, {:images, slug}})
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

  def handle_call({:has_chapters?, slug}, _from, state) do
    reply = case consult_file(get_book_dir(slug), "chapters.db") do
      [] -> false
      _  -> true
    end
    {:reply, reply, state}
  end

  def handle_call({:load_image, {slug, image, user}}, _from, state) do
    {:reply, do_load_image(slug, image, user), state}
  end

  def handle_call({:copy_chapter_to_chaff, {slug, chapter_slug, chaff_title, user}},
    _from, state) do
    {:reply, do_copy_chapter_to_chaff(slug, chapter_slug, chaff_title, user), state}
  end

  def handle_call({:create, {type, slug, chapter_title, user}}, _from, state) do
    {:reply, do_create(type, slug, chapter_title, user), state}
  end

  def handle_call({:update_book_title, {slug, new_title, user}}, _from, state) do
    {:reply, do_update_book_title(slug, new_title, user), state}
  end

  def handle_call({:update_chaff, {slug, chaff_slug,
                                   commit_title, commit_msg,
                                   data, tag_bump, user}}, _from, state) do
    reply = do_update_chaff(slug, chaff_slug, commit_title, commit_msg,
      data, tag_bump, user)
    {:reply, reply, state}
  end

  def handle_call({:update_chapter, {slug, chapter_slug,
                                     commit_title, commit_msg,
                                     data, tag_bump, user}}, _from, state) do
    reply = do_update_chapter(slug, chapter_slug, commit_title, commit_msg,
      data, tag_bump, user)
    {:reply, reply, state}
  end

  def handle_call({:create_book, {book_title, author}}, _from, state) do
    {:reply, do_create_book(book_title, author), state}
  end

  def handle_call({:get_current_tag_msg, slug}, _from, state) do
    {:reply, do_get_current_tag_msg(get_book_dir(slug)), state}
  end

  def handle_call({:get_book_title, slug}, _from, state) do
    {:ok, title} = read_file(get_book_dir(slug), "title.db")
    {:reply, title, state}
  end

  def handle_call({:get_chapters_dropdown, slug}, _from, state) do
    {:reply, do_get_chapters_dropdown(slug), state}
  end

  def handle_call({:get_chaff, {slug, chaffslug}}, _from, state) do
    {:reply, do_get_text(slug, :chaff, chaffslug), state}
  end

  def handle_call({:get_chapter, {slug, chapterslug}}, _from, state) do
    {:reply, do_get_text(slug, :chapter, chapterslug), state}
  end

  def handle_call({:get_chaff_title, {slug, chaffslug}}, _from, state) do
    {:reply, do_get_chaff_title(slug, chaffslug), state}
  end

  def handle_call({:get_chapter_title, {slug, chapterslug}}, _from, state) do
    {:reply, do_get_chapter_title(slug, chapterslug), state}
  end

  def handle_call({:get, {type, slug}}, _from, state) do
    {:reply, do_get(type, slug), state}
  end

  def handle_call(:get_books, _from, state) do
    {:reply, do_get_books(), state}
  end

  def handle_call({:read, {slug, file}}, _from, state) do
    {:reply, read_file(get_book_dir(slug), file), state}
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
    bookdir
    |> copy_image(imageslug, tmp_image_path)
    |> update_imagesDB(imagename, filename, shortimageslug, ext)
    |> add_to_git(:all)
    |> commit_to_git(commitmsg)
    |> bump_tag("new image loaded " <> imageslug, "major", user)
    |> push_to_github(slug)
    |> push_to_channel(slug, slug, "book-get_images")
    :ok
  end

  defp copy_image(dir, titleslug, tmp_image_path) do
    path = Path.join(dir, "images")
    to   = Path.join(path, titleslug)
    :ok = File.cp(tmp_image_path, to)
    dir
  end

  defp do_update_book_title(slug, new_title, user) do
    bookdir = get_book_dir(slug)
    {:ok, oldtitle} = read_file(get_book_dir(slug), "title.db")
    commitmsg = "old title was " <> oldtitle <> "new title is "
    <> new_title <> "(" <> slug <> ")"
    tag = make_tag("edit book title", new_title, slug, user, "new book title ")
    bookdir
    |> write_to_book("title.db", new_title)
    |> add_to_git(:all)
    |> commit_to_git(commitmsg)
    |> bump_tag(tag, "major", user)
    |> push_to_github(slug)
    |> push_to_channel(slug, slug, "books-list")
    |> push_to_channel(slug, slug, "book-get_book_title")
    :ok
  end

  defp do_update_chaff(slug, ch_slug, commit_title, commit_msg,
    data, tag_bump, user) do
    bookdir  = get_book_dir(slug)
    ch_title =  do_get_chapter_title(slug, ch_slug)
    tag = make_tag("update chaff", ch_title, ch_slug, user, commit_title)
    chapter  = Path.join("chaff", ch_slug <> ".eider")
    route    = make_route([slug, "chaff", ch_slug])
    # the user may have pressed save without making any changes
    # so we write the data, check if there is any change
    # and then, and only then, retag etc
    bookdir
    |> write_to_book(chapter, data)
    case nothing_to_commit?(bookdir) do
      true ->
        msg = "no changes to save: " <> do_get_current_tag_msg(bookdir)
        :ok = direct_push_to_channel(route, "book-save_chaff_edits", msg)
        msg
      false ->
        bookdir
        |> make_html(:chaff, ch_title, ch_slug, user)
        |> add_to_git(:all)
        |> commit_to_git(commit_msg)
        |> bump_tag(tag, tag_bump, user)
        |> push_to_github(slug)
        |> push_to_channel(slug, route, "book-save_chaff_edits")
        |> do_get_current_tag_msg
    end
  end

  defp do_update_chapter(slug, ch_slug, commit_title, commit_msg,
    data, tag_bump, user) do
    bookdir  = get_book_dir(slug)
    ch_title =  do_get_chapter_title(slug, ch_slug)
    tag = make_tag("update chapter", ch_title, ch_slug, user, commit_title)
    chapter  = Path.join("chapters", ch_slug <> ".eider")
    route    = make_route([slug, "chapter", ch_slug])
    # the user may have pressed save without making any changes
    # so we write the data, check if there is any change
    # and then, and only then, retag etc
    bookdir
    |> write_to_book(chapter, data)
    case nothing_to_commit?(bookdir) do
      true ->
        msg = "no changes to save: " <> do_get_current_tag_msg(bookdir)
        :ok = direct_push_to_channel(route, "book-save_chapter_edits", msg)
        msg
      false ->
        bookdir
        |> make_html(:chapter, ch_title, ch_slug, user)
        |> add_to_git(:all)
        |> commit_to_git(commit_msg)
        |> bump_tag(tag, tag_bump, user)
        |> push_to_github(slug)
        |> push_to_channel(slug, route, "book-save_chapter_edits")
        |> do_get_current_tag_msg
    end
  end

  defp do_copy_chapter_to_chaff(slug, chapter_slug, chaff_title, user) do
    chaff_slug = Incunabula.Slug.to_slug(chaff_title)
    bookdir = get_book_dir(slug)
    from = Path.join([bookdir, "chapters", chapter_slug <> ".eider"])
    to   = Path.join([bookdir, "chaff",    chaff_slug   <> ".eider"])
    case File.exists?(to) do
      false ->
        {:ok, 0} = File.copy(from, to)
        prefix = chaff_slug <> " copied from " <> chapter_slug
        tag = make_tag(prefix, chaff_title, chaff_slug, user)
        currenttag = get_current_tag(bookdir)
        bookdir
        |> update_chaff_DB_annotated(chaff_title, chaff_slug, prefix <> " at " <> currenttag)
        |> add_to_git(:all)
        |> make_html(:chaff, chaff_title, chaff_slug, user)
        |> commit_to_git(tag)
        |> bump_tag(tag, "major", user)
        |> push_to_github(slug)
        |> push_to_channel(slug, slug, "book-get_chaffs")
        :ok
        true ->
        {:error, chaff_slug <> " already exists"}
    end
  end

  defp do_create(type, slug, title, user) do
    title_slug = Incunabula.Slug.to_slug(title)
    bookdir = get_book_dir(slug)
    subdir = case type do
               :chapter -> "chapters"
               :chaff   -> "chaff"
             end
    fileroot = Path.join([bookdir, subdir, title_slug])
    file     = Path.join([bookdir, subdir, title_slug <> ".eider"])
    case File.exists?(file) do
      false ->
        :ok = File.touch(file)
        # creating a new chapter is a banal event
        # so we just reuse the tag for the commit msg
        prefix = case type do
                   :chapter -> "create new chapter"
                   :chaff   -> "create new chaff"
                 end
        channel = case type do
                   :chapter -> "book-get_chapters"
                   :chaff   -> "book-get_chaffs"
                 end
        tag = make_tag(prefix, title, title_slug, user)
        bookdir
        |> update_DB(type, title, title_slug)
        |> add_to_git(:all)
        |> make_html(type, title, title_slug, user)
        |> commit_to_git(tag)
        |> bump_tag(tag, "major", user)
        |> push_to_github(slug)
        |> push_to_channel(slug, slug, channel)
        case type == :chapter do
          true ->
            bookdir = push_to_channel(bookdir, slug, slug, "book-get_chapters_dropdown")
            :ok
          false ->
            :ok
        end
      true ->
        {:error, title <> " already exists"}
    end
  end

  defp update_imagesDB(bookdir, image_title, origfilename, image_slug, ext) do
    imagedetails = get_image_details(bookdir, image_slug)
    newentry = %{title:         image_title,
                 original_name: origfilename,
                 image_slug:    image_slug,
                 image_details: imagedetails,
                 extension:     ext}
    old_images = consult_file(bookdir, "images.db")
    new_images = old_images ++ [newentry]
    images = :io_lib.format('~p.~n', [new_images])
    write_to_book(bookdir, "images.db", images)
  end

  defp update_chaff_DB_annotated(bookdir, title, slug, msg) do
    newentry =  %{chaff_title: title,
                  creation:     msg,
                  chaff_slug:   slug}
    db =  "chaff.db"
    do_update_DB(bookdir, db, newentry)
  end

  defp update_DB(bookdir, :chapter, title, slug) do
    newentry =  %{chapter_title: title,
                  chapter_slug:   slug}
    db = "chapters.db"
    do_update_DB(bookdir, db, newentry)
  end

  defp update_DB(bookdir, :chaff, title, slug) do
    currenttag = get_current_tag(bookdir)
    newentry =  %{chaff_title: title,
                  creation:     "ex novo at " <> currenttag,
                  chaff_slug:   slug}
    db =  "chaff.db"
    do_update_DB(bookdir, db, newentry)
  end

  defp do_update_DB(bookdir, db, newentry) do
    old = consult_file(bookdir, db)
    new = old ++ [newentry]
    contents = :io_lib.format('~p.~n', [new])
    write_to_book(bookdir, db, contents)
  end

  defp get_image_details(dir, image_file) do
    args = [
      to_string(Path.join([dir, "images", image_file]))
    ]
    workingdir = to_string(Path.join(dir, "images"))
    details = System.cmd("file", args, [cd: workingdir])
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
        |> write_to_book("title.db",    book_title)
        |> write_to_book("author.db",   author)
        |> write_to_book(".gitignore",  standard_gitignore())
        |> write_to_book("chapters.db", :io_lib.format('~p.~n', [[]]))
        |> write_to_book("chaff.db",    :io_lib.format('~p.~n', [[]]))
        |> write_to_book("images.db",   :io_lib.format('~p.~n', [[]]))
        |> make_component_dirs("chapters")
        |> make_component_dirs("images")
        |> make_component_dirs("preview_html")
        |> make_component_dirs("chaff")
        |> make_component_dirs("chaff_html")
        |> add_to_git(:all)
        |> commit_to_git("basic setup of directory")
        |> tag_github(0, 1, 1, "initial creation of " <> slug, author)
        |> push_to_github(slug)
        |> push_to_channel("", "", "books-list")
        {:ok, slug}
      true ->
        {:error, "The book " <> slug <> " exists already"}
    end
  end

  defp do_get_current_tag_msg(dir) do
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
    chapters = consult_file(get_book_dir(slug), "chapters.db")
    _dropdown = Incunabula.FragController.get_chapters_dropdown(slug, chapters)
  end

  defp do_get_text(slug, type, textslug) do
    bookdir = get_book_dir(slug)
    tag = do_get_current_tag_msg(bookdir)
    path = case type do
             :chapter -> Path.join([get_book_dir(slug), "chapters"])
             :chaff   -> Path.join([get_book_dir(slug), "chaff"])
           end
    {:ok, contents} = read_file(path, textslug <> ".eider")
    {tag, contents}
  end

  defp do_get_chaff_title(slug, chaffslug) do
    chaff  = consult_file(get_book_dir(slug), "chaff.db")
    _title = read_chaff_title(chaffslug, chaff)
  end

  defp do_get_chapter_title(slug, chapterslug) do
    chapters = consult_file(get_book_dir(slug), "chapters.db")
    _title   = read_chapter_title(chapterslug, chapters)
  end

  defp read_chaff_title(slug, [%{chaff_slug:  slug,
                                 chaff_title: chaff_title} | _T]) do
    chaff_title
  end

  defp read_chaff_title(slug, [_H | T]) do
    get_chaff_title(slug, T)
  end

  defp read_chapter_title(slug, [%{chapter_slug:  slug,
                                  chapter_title: chapter_title} | _T]) do
    chapter_title
  end

  defp read_chapter_title(slug, [_H | T]) do
    get_chapter_title(slug, T)
  end

  defp do_get(:chaffs, slug) do
    chapters = consult_file(get_book_dir(slug), "chaff.db")
    _html    = Incunabula.FragController.get_chaffs(slug, chapters)
  end

  defp do_get(:chapters, slug) do
    chapters = consult_file(get_book_dir(slug), "chapters.db")
    _html    = Incunabula.FragController.get_chapters(slug, chapters)
  end

  defp do_get(:images, slug) do
    images = consult_file(get_book_dir(slug), "images.db")
    _html  = Incunabula.FragController.get_images(slug, images)
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
    books = for s <- slugs, {:ok, t} = File.read(Path.join([rootdir, s, "title.db"])) do
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
    # {_, 0} = System.cmd("curl", args)
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
  or type == "release" do
    tag = get_current_tag(dir)
    [i, j, k] = String.split(tag, ".")
    {release, major, minor} = case type do
                                "major" ->
                                  {i, to_string(String.to_integer(j) + 1), "0"}
                                "minor" ->
                                  {i, j, to_string(String.to_integer(k) + 1)}
                                "release" ->
                                  {to_string(String.to_integer(i) + 1), 0, 0}
                     end
    tag_github(dir, release, major, minor, msg, person)
    dir
  end

  defp tag_github(dir, release, major, minor, msg, person) do
    args = [
      "tag",
      "-a",
      to_string(release) <> "." <> to_string(major) <> "." <> to_string(minor),
      "-m",
      msg <> "\ncommited by " <> person
    ]
    {"", 0} = System.cmd("git", args, [cd: dir])
    dir
  end

  defp push_to_github(dir, repo) do
    cmd = "git"
    github_account = get_env(:github_account)
    githubPAT = get_env(:personal_access_token)
    url = Path.join([
      "https://" <> githubPAT <> "@github.com",
      github_account,
      repo <> ".git"
    ])
    args = [
      "push",
      "--repo=" <> url
    ]
    # {"", 0} = System.cmd(cmd, args, [cd: dir])
    dir
  end

  defp push_to_channel(dir, _slug, _route, "books-list") do
    books = do_get_books()
    Incunabula.Endpoint.broadcast "books:list", "books", %{books: books}
    dir
  end

  defp push_to_channel(dir, slug, route, "book-get_book_title") do
    {:ok, title} = read_file(get_book_dir(slug), "title.db")
    # No I don't understand why the event and the message associated with it
    # have to be called books neither
    Incunabula.Endpoint.broadcast "book:get_book_title:" <> route,
      "books", %{books: title}
    dir
  end

  defp push_to_channel(dir, slug, route, "book-get_chaffs") do
    chaffs = do_get(:chaffs, slug)
    # No I don't understand why the event and the message associated with it
    # have to be called books neither
    Incunabula.Endpoint.broadcast "book:get_chaffs:" <> route,
      "books", %{books: chaffs}
    dir
  end

  defp push_to_channel(dir, slug, route, "book-get_chapters_dropdown") do
    chapters = do_get(:chapters, slug)
    # No I don't understand why the event and the message associated with it
    # have to be called books neither
    Incunabula.Endpoint.broadcast "book:get_chapters_dropdown:" <> route,
      "books", %{books: chapters}
    dir
  end

  defp push_to_channel(dir, slug, route, "book-get_chapters") do
    chapters = do_get(:chapters, slug)
    # No I don't understand why the event and the message associated with it
    # have to be called books neither
    Incunabula.Endpoint.broadcast "book:get_chapters:" <> route,
      "books", %{books: chapters}
    dir
  end

  defp push_to_channel(dir, slug, route, "book-get_images") do
    images = do_get(:images, slug)
    # No I don't understand why the event and the message associated with it
    # have to be called books neither
    Incunabula.Endpoint.broadcast "book:get_images:" <> route,
      "books", %{books: images}
    dir
  end

  defp push_to_channel(dir, slug, route, "book-save_chaff_edits") do
    bookdir = get_book_dir(slug)
    tag = do_get_current_tag_msg(bookdir)
    # No I don't understand why the event and the message associated with it
    # have to be called books neither
    Incunabula.Endpoint.broadcast "book:save_chaff_edits:" <> route,
      "books", %{books: tag}
    dir
  end

  defp push_to_channel(dir, slug, route, "book-save_chapter_edits") do
    bookdir = get_book_dir(slug)
    tag = do_get_current_tag_msg(bookdir)
    # No I don't understand why the event and the message associated with it
    # have to be called books neither
    Incunabula.Endpoint.broadcast "book:save_chapter_edits:" <> route,
      "books", %{books: tag}
    dir
  end

  defp direct_push_to_channel(route, "book-save_chaff_edits", msg) do
    Incunabula.Endpoint.broadcast "book:save_chaff_edits:" <> route,
      "books", %{books: msg}
    :ok
  end

  defp direct_push_to_channel(route, "book-save_chapter_edits", msg) do
    Incunabula.Endpoint.broadcast "book:save_chapter_edits:" <> route,
      "books", %{books: msg}
    :ok
  end

  defp do_git_init(dir) do
    return = System.cmd("git", ["init"], cd: dir)
    # force a crash if this failed
    {<<"Initialised empty Git repository in">> <> _rest, _} = return
    dir
  end

  defp write_to_book(dir, file, data) do
    path = Path.join([dir, file])
    :ok = File.write(path, data)
    dir
  end

  defp make_component_dirs(dir, type) do
    :ok = File.mkdir(Path.join([dir, type]))
    dir
  end

  def read_file(dir, file) do
    File.read(Path.join([dir, file]))
  end

  def consult_file(dir, file) do
    path = Path.join(dir, file)
    {:ok, [terms]} = :file.consult(path)
    terms
  end

  defp standard_gitignore() do
    "lock.file"
  end

  defp get_book_dir(slug) do
    Path.join(get_books_dir(), slug)
  end

  defp log(dir, msg) do
    IO.inspect msg
    dir
  end

  defp wrap_in_quotes(string) when is_binary(string) do
    "\"" <> string <> "\""
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

  defp make_html(dir, :chapter, chapter_title, chapter_slug, user) do
    eiderdownfile = Path.join([dir, "chapters",     chapter_slug <> ".eider"])
    webpage       = Path.join([dir, "preview_html", chapter_slug  <> ".html"])
    {:ok, eiderdown} = File.read(eiderdownfile)
    body = to_string(:eiderdown.conv(to_charlist(eiderdown)))
    html = Incunabula.HTMLController.make_preview(chapter_title, user, body)
    :ok = File.write(webpage, html)
    dir
  end

  defp make_html(dir, :chaff, chaff_title, chaff_slug, user) do
    eiderdownfile = Path.join([dir, "chaff",      chaff_slug <> ".eider"])
    webpage       = Path.join([dir, "chaff_html", chaff_slug  <> ".html"])
    {:ok, eiderdown} = File.read(eiderdownfile)
    body = to_string(:eiderdown.conv(to_charlist(eiderdown)))
    html = Incunabula.ChaffHTMLController.make_preview(chaff_title, user, body)
    :ok = File.write(webpage, html)
    dir
  end

  defp make_route(list) do
    Enum.join(list, ":")
  end

end
