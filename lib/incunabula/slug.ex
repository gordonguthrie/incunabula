defmodule Incunabula.Slug do

  def to_slug(str) when is_binary(str) do
		str
		|> String.downcase()
		|> String.replace(~r/[^\w-]+/u, "-")
  end

end
