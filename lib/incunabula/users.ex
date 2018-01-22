defmodule Incunabula.Users do

  def get_users() do
    path = Path.join(:code.priv_dir(:incunabula), "users/users.config")
    {:ok, [users: users]} = :file.consult(path)
    for {user, password} <- users, do: user
  end

end
