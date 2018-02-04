defmodule Incunabula.Router do
  use Incunabula.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Incunabula.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Incunabula do
    pipe_through :browser # Use the default browser stack

    get  "/",                                          PageController,    :index
    get  "/books",                                     BookController,    :index
    post "/book/new",                                  BookController,    :create
    get  "/books/:slug",                               BookController,    :show
    post "/books/:slug/chapter/new",                   ChapterController, :create
    post "/books/:slug/chaff/new",                     ChaffController,   :new
    post "/books/:slug/chaff/copy",                    ChaffController,   :copy
    get  "/books/:slug/chapters/:chapterslug",         ChapterController, :show
    get  "/books/:slug/chapters/:chapterslug/preview", ChapterController, :show_preview
    post "/books/:slug/image/new",                     ImageController,   :create
    get  "/books/:slug/images/:imageslug",             ImageController,   :show
    get  "/books/:slug/chaff",                         ChaffController,   :index
    get  "/admin",                                     AdminController,   :index
    get  "/login",                                     LoginController,   :index
    post "/login",                                     LoginController,   :login
    get  "/logout",                                    LoginController,   :logout
  end

  # Other scopes may use custom stacks.
  # scope "/api", Incunabula do
  #   pipe_through :api
  # end
end
