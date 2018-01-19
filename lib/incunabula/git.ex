defmodule Incunabula.Git do

  use GenServer

  require Logger

  # api

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, []}
  end

  def get_books(dir) do
    GenServer.call(__MODULE__, {:get_books, dir})
  end

  # call backs

  def handle_call({:get_books, dir}, _from, state) do
    {:reply, do_get_books(dir), state}
  end


  defp do_get_books(dir) when is_binary(dir) do
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

end
