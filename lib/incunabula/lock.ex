defmodule Incunabula.Lock do

  use GenServer

  @ticktime   5000 # in microseconds
  @expirytime 10    # in seconds

  @moduledoc """
  This is the lock server for editing chapters, chaffs and reviews

  Only one person can edit them at a time on one device
  It is explicit locking

  There is a time out of 2 mins (auto save is 1 minute) so
  if you forget you editing on your phone or other computer
  or whatever you are only locked out for 1 minute
  """

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    time = Integer.to_string(:os.system_time(:seconds))
    salt = get_env(:cryptographic_salt) <> time
    Process.send_after(self(), :tick, @ticktime)
    {:ok, %{:salt => salt, :locks => []}}
  end

  def acquire_lock(path) do
    GenServer.call(__MODULE__, {:acquire_lock, path})
  end

  def inspect_lock(path) do
    GenServer.call(__MODULE__, {:inspect_lock, path})
  end

  def handle_call({:acquire_lock, path}, _from, state) do
    %{:salt  => salt,
      :locks => locks} = state
    {reply, newstate}
    = case List.keyfind(locks, path, 0) do
        nil ->
          time = :os.system_time(:seconds)
          lock = make_hash(path, salt <> to_string(time))
          newlocks = locks ++ [{path, lock, time}]
          # now broadcast the lock
          topic = "book:inspect_lock:" <> path
          Incunabula.Endpoint.broadcast topic, "books", %{books: lock}
          {{:ok, lock}, Map.put(state, :locks, newlocks)}
        {_path, _lock, _timestamp} ->
          {{:error, :locked}, state}
      end
    {:reply, reply, newstate}
  end

def handle_call({:inspect_lock, path}, _from, state) do
    %{:locks => locks} = state
    {_path, lock, _timestamp} = List.keyfind(locks, path, 0)
    reply = lock
    {:reply, reply, state}
  end

  def handle_info(:tick, %{:locks => locks} = state) do
    now = :os.system_time(:seconds)
    newlocks = expire(locks, now)
    Process.send_after(self(), :tick, @ticktime)
    {:noreply, Map.put(state, :locks, newlocks)}
  end

  defp make_hash(path, salt) do
    :crypto.hash(:sha256, salt <> path)
    |> Base.encode16
    |> String.downcase
  end

  defp get_env(key) do
    config = Application.get_env(:incunabula, :configuration)
    config[key]
  end

  defp expire(locks, now) do
    Enum.filter(locks, fn({_, _, time}) ->
      ((now - time) < @expirytime)
    end)
  end

end
