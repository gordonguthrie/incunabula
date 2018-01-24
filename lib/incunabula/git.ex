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

  def check_github() do
    githubPAT = get_env(:personal_access_token)
    args = [
      "-i",
      "-H",
      "\"Authorization: token "  <> githubPAT <> "\"",
      'https://api.github.com/user/repos'
    ]
    _ret = System.cmd("curl", args)
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
    slug = sluggify(book_title)
    bookdir = Path.join(dir, slug)
    case File.exists?(bookdir) do
      false ->
        bookdir
        |> make_dir
        |> do_git_init
        |> write_to_book("title", book_title)
        |> write_to_book(".gitignore", standard_gitignore())
        :ok
      true ->
        {:error, "The book " <> slug <> " exists already"}
    end
  end

  defp do_get_books() do
    dir = get_books_dir()
    IO.inspect dir
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
    subs   = for f <- files, File.dir?(rootdir <> "/" <> f), do: f
    _books = for d <- subs,  File.dir?(rootdir <> "/" <> d <> "/.git"), do: d
  end

  defp get_env(key) do
    configs = Application.get_env(:incunabula, :configuration)
    configs[key]
  end

	defp sluggify(str) do
		str
		|> String.downcase()
		|> String.replace(~r/[^\w-]+/u, "-")
  end

  defp make_dir(dir) do
    :ok = File.mkdir(dir)
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
