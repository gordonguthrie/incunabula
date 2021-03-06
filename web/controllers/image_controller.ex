defmodule Incunabula.ImageController do
  use Incunabula.Web, :controller

  use Incunabula.Controller

  plug :authenticate_author_or_reviewer when action in [:show, :index, :create]

  def show(conn, %{"imageslug" => image,
                   "slug"      => slug}, _user) do
    booksdir = Incunabula.Git.get_books_dir()
    file = Path.join([booksdir, slug, "images", image])
    {:ok, binary} = File.read(file)
    conn
    |> put_resp_content_type("application/octet-stream")
    |> send_resp(200, binary)
  end

  def create(conn, %{"image" => image,
                     "slug"  => slug}, user) do
    case is_valid_image?(image) do
      true ->
        case Incunabula.Git.load_image(slug, image, user) do
          :ok ->
            conn
            |> redirect(to: Path.join(["/books/", slug, "#images"]))
          {:error, upload_error} ->
            conn
            |> put_flash(:error, upload_error)
            |> redirect(to: Path.join(["/books/", slug, "#images"]))
        end
      {:error, error} ->
        conn
        |> put_flash(:error, error)
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
          _       -> {:error, "not a valid image type"}
        end
      false -> {:error, "images must have titles"}
    end
  end

  defp is_valid_image?(_) do
    {:error, "you must select a file"}
  end

end
