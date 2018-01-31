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

  def create_chapter(slug, chapter_title) do
    GenServer.call(__MODULE__, {:create_chapter, {slug, chapter_title}})
  end


  def create_book(book_title) do
    GenServer.call(__MODULE__, {:create_book, book_title})
  end

  def get_books() do
    GenServer.call(__MODULE__, :get_books)
  end

  def get_books_dir() do
    _dir = Path.join(get_env(:root_directory), "books")
  end

  def get_title(slug) do
    GenServer.call(__MODULE__, {:read, {slug, "title.db"}})
  end

  def get_chapters(slug) do
    GenServer.call(__MODULE__, {:get_chapters, slug})
  end

  def get_images(slug) do
    GenServer.call(__MODULE__, {:get_images, slug})
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

  def handle_call({:create_chapter, {slug, chapter_title}}, _from, state) do
    {:reply, do_create_chapter(slug, chapter_title), state}
  end

  def handle_call({:get_chapters, slug}, _from, state) do
    chapters = consult_file(get_book_dir(slug), "chapters.db")
    html = Incunabula.FragController.get_chapters(slug, chapters)
    {:reply, html, state}
  end

  def handle_call({:get_images, slug}, _from, state) do
    chapters = consult_file(get_book_dir(slug), "images.db")
    html = Incunabula.FragController.get_images(slug, chapters)
    {:reply, html, state}
  end

  def handle_call(:get_books, _from, state) do
    {:reply, do_get_books(), state}
  end

  def handle_call({:create_book, book_title}, _from, state) do
    {:reply, do_create_book(book_title), state}
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

  defp do_create_chapter(slug, chapter_title) do
     chapter_slug = Incunabula.Slug.to_slug(chapter_title)
    bookdir = get_book_dir(slug)
    content = Path.join([bookdir, "chapters", chapter_slug <> ".ed"])
    case File.exists?(content) do
      false ->
        :ok = File.touch(content)
        bookdir
        |> update_chapters(chapter_title, chapter_slug)
        |> add_to_git(:all)
        |> commit_to_git("create new chapter: " <>
          chapter_title <>
          " - "         <>
          chapter_slug)
        |> push_to_github(slug)
        :ok
      true ->
        # don't care really
        :ok
    end
  end

  defp update_chapters(bookdir, chapter_title, chapter_slug) do
    old_chapters = consult_file(bookdir, "chapters.db")
    new_chapters = old_chapters ++ [{chapter_title, chapter_slug}]
    contents = :io_lib.format('~p.~n', [new_chapters])
    write_to_book(bookdir, "chapters.db", contents)
  end

  defp do_create_book(book_title) do
    slug = Incunabula.Slug.to_slug(book_title)
    bookdir = get_book_dir(slug)
    case File.exists?(bookdir) do
      false ->
        :ok = create_repo_on_github(slug)
        bookdir
        |> make_dir
        |> do_git_init
        |> write_to_book("title.db", book_title)
        |> write_to_book(".gitignore", standard_gitignore())
        |> write_to_book("chapters.db", :io_lib.format('~p.~n', [[]]))
        |> write_to_book("images.db",   :io_lib.format('~p.~n', [[]]))
        |> make_component_dirs("chapters")
        |> make_component_dirs("images")
        |> add_to_git(:all)
        |> commit_to_git("basic setup of directory")
        |> push_to_github(slug)
        |> push_to_channel(:"books-list")
        {:ok, slug}
      true ->
        {:error, "The book " <> slug <> " exists already"}
    end
  end

  defp do_get_books() do
    dir = get_books_dir()
    case File.ls(dir) do
      {:ok, files} ->
        IO.inspect files
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
    {return, 0} = System.cmd(cmd, args, [cd: dir])
    # force a crash if this failed
    <<"[master ">> <> _rest = return
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

  defp push_to_channel(dir, :"books-list") do
    books = do_get_books()
    Incunabula.Endpoint.broadcast "books:list", "books", %{books: books}
    dir
  end

  defp do_git_init(dir) do
    return = System.cmd("git", ["init"], cd: dir)
    # force a crash if this failed
    {<<"Initialised empty Git repository in">> <> _rest, _} = return
    dir
  end

  defp write_to_book(dir, file, chapters) do
    path = Path.join([dir, file])
    :ok = File.write(path, chapters)
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

end
