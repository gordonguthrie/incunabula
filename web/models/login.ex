defmodule Incunabula.Login do
  use Incunabula.Web, :model

  @moduledoc """
  # I am being a bad person here
  # we are not using Ecto for our changesets
  # to persist data
  # so I am spoofing it by:
  # * manually defining the struct (instead of using schema)
  # * calling 'Elixir.Ecto.Changeset.cast/3' explicitly
  # * implementing the function '__changeset__'/0 manually
  """

  # generated by 'schema' fn normally
  defstruct username: "", password: ""

  # This fn would normally be automagiced by various macro's and shit
  def __changeset__() do
    %{id:        Incubula.Login,
      username:  :string,
      password:  :string}
  end

  def changeset() do
    Elixir.Ecto.Changeset.cast(%Incunabula.Login{}, %{}, [])
  end

end
