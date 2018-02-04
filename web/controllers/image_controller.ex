defmodule Incunabula.ImageController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_user when action in [:show, :create, :index]

  def show(conn, %{"imageslug" => image,
                   "slug"      => slug}, user) do
    booksdir = Incunabula.Git.get_books_dir()
    file = Path.join([booksdir, slug, "images", image])
    {:ok, binary} = File.read(file)
    conn
    |> put_resp_content_type("application/octet-stream")
    |> send_resp(200, binary)
  end

  def create(conn, %{"image" => image,
                     "slug"  => slug} = params, user) do
    case is_valid_image?(image) do
      true ->
        :ok = Incunabula.Git.load_image(slug, image, user)
        conn
        |> redirect(to: Path.join(["/books/", slug, "#images"]))
      false ->
        conn
        |> put_flash(:error, "Not a valid image name")
        |> redirect(to: Path.join(["/books/", slug, "#images"]))
    end
  end

  def index(conn, _params) do
    render conn, "index.html"
  end

  defp is_valid_image?(%{"image_title"    => image_title,
                         "uploaded_image" => uploaded_image}) do
    %Plug.Upload{filename: filename} = uploaded_image
    ext = String.downcase(Path.extname(filename))
    case image_title != "" do
      true ->
        case ext do
          ".jpg"  -> true
          ".jpeg" -> true
          ".png"  -> true
          ".gif"  -> true
          ".tiff" -> true
          _       -> false
        end
      false -> false
    end
  end

end
