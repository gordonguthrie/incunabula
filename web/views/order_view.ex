defmodule Incunabula.OrderView do
  use Incunabula.Web, :view

  def render("index.json", %{chapters: chapters}) do
    %{"chapters" => chapters}
  end

end
