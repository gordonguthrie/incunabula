defmodule Incunabula.OrderController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_author when action in [
    :read,
    :write
  ]

  def read(conn, %{"slug" => slug}, _user) do
    chapters = Incunabula.Git.get_chapters_json(slug)
    render(conn, "index.json",
      chapters: chapters)
  end

  def write(conn, %{"chapters" => json_chapters,
                    "slug"     => slug}, user) do
    list = Map.to_list(json_chapters)
    # yeah the browser appears to respect the order of the array in the json
    # but a wise head don't trust that sort of thang and resorts the data
    # on the indexes before saving it
    sorted_list = Enum.sort(list, &(String.to_integer(hd(Tuple.to_list(&1)))
          <= String.to_integer(hd(Tuple.to_list(&2)))))
    chapters = for {_, %{"chapter_slug"  => c_slug,
                         "chapter_title" => c_title}}
    <- sorted_list, do: %{chapter_slug:  c_slug,
                          chapter_title: c_title}
    :ok = Incunabula.Git.update_chapter_order(slug, chapters, user)
    conn
    |> send_resp(200, <<"ok">>)
  end


end
