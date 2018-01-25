defmodule Incunabula.Git do

  use GenServer

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

  def create_book(book_title) do
    GenServer.call(__MODULE__, {:create_book, book_title})
  end

  def get_books() do
    GenServer.call(__MODULE__, :get_books)
  end

  def get_books_dir() do
    _dir = Path.join(get_env(:root_directory), "books")
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

  def handle_call(:get_books, _from, state) do
    {:reply, do_get_books(), state}
  end

  def handle_call({:create_book, book_title}, _from, state) do
    {:reply, do_create_book(book_title), state}
  end

  defp do_create_book(book_title) do
    dir = get_books_dir()
    slug = Incunabula.Slug.to_slug(book_title)
    bookdir = Path.join(dir, slug)
    case File.exists?(bookdir) do
      false ->
        :ok = create_repo_on_github(slug)
        bookdir
        |> make_dir
        |> do_git_init
        |> write_to_book("title", book_title)
        |> write_to_book(".gitignore", standard_gitignore())
        |> add_to_git(:all)
        |> commit_to_git("basic setup of directory")
        |> push_to_github(slug)
        {:ok, slug}
      true ->
        {:error, "The book " <> slug <> " exists already"}
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
    books = for s <- slugs, {:ok, t} = File.read(Path.join([rootdir, s, "title"])) do
      {t, s}
  end
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
    {_, 0} = System.cmd("curl", args)
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
    <<"[master (root-commit) ">> <> _rest = return
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
    {"", 0} = System.cmd(cmd, args, [cd: dir])
    dir
  end

  defp do_git_init(dir) do
    return = System.cmd("git", ["init"], cd: dir)
    # force a crash if this failed
    {<<"Initialised empty Git repository in">> <> _rest, _} = return
    dir
  end

  defp write_to_book(dir, file, contents) do
    :ok = File.write(Path.join(dir, file), contents)
    dir
  end

  defp standard_gitignore() do
    "lock.file"
  end

end
