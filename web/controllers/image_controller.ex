defmodule Incunabula.ImageController do
  use Incunabula.Web, :controller

  def create(conn, %{"image" => image,
                    "slug"   => slug} = params) do
    case is_valid_image?(image) do
      true ->
        :ok = Incunabula.Git.load_image(slug, image)
        conn
        |> redirect(to: "/books/" <> slug)
      false ->
        conn
        |> put_flash(:error, "Not a valid image name")
        |> redirect(to: "/books/" <> slug)
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
