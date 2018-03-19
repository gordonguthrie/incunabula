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

    get  "/",                                               PageController,     :index
    get  "/books",                                          BookController,     :index
    post "/book/new",                                       BookController,     :create
    get  "/books/:slug",                                    BookController,     :show
    get  "/books/:slug/history",                            BookController,     :history
    post "/books/:slug/chapter/new",                        ChapterController,  :create
    post "/books/:slug/chaff/new",                          ChaffController,    :new
    post "/books/:slug/chaff/copy",                         ChaffController,    :copy
    get  "/books/:slug/chaffs/:chaffslug",                  ChaffController,    :show
    post "/books/:slug/newreviewer",                        ReviewerController, :newreviewer
    post "/books/:slug/removereviewer/:reviewer",           ReviewerController, :removereviewer
    post "/books/:slug/review/copy",                        ReviewController,   :copy
    get  "/books/:slug/reviews/:reviewslug",                ReviewController,   :show
    post "/books/:slug/reviews/:reviewslug/changestatus",   ReviewController,   :change_status
    get  "/books/:slug/chapters/:chapterslug",              ChapterController,  :show
    get  "/books/:slug/chaffs/:chaffslug/preview",          PreviewController,  :show
    get  "/books/:slug/reviews/:reviewslug/preview",        PreviewController,  :show
    get  "/books/:slug/reviews/:reviewslug/reconciliation", ReviewController,   :reconcile
    get  "/books/:slug/chapters/:chapterslug/preview",      PreviewController,  :show
    get  "/books/:slug/chapters/:chapterslug/tag/:tag",     PreviewController,  :show_tag
    get  "/books/:slug/chapters/:chapterslug/summary",      PreviewController,  :summary
    post "/books/:slug/image/new",                          ImageController,    :create
    get  "/books/:slug/images/:imageslug",                  ImageController,    :show
    get  "/books/:slug/chaff",                              ChaffController,    :index
    get  "/books/:slug/reviews",                            ReviewController,   :index
    get  "/books/:slug/chapter_order",                      OrderController,    :read
    post "/books/:slug/chapter_order",                      OrderController,    :write
    get  "/help",                                           HelpController,     :index
    get  "/admin",                                          AdminController,    :index
    post "/admin/adduser",                                  AdminController,    :adduser
    post "/admin/changepassword",                           AdminController,    :changepassword
    post "/admin/deleteuser/:username",                     AdminController,    :deleteuser
    get  "/login",                                          LoginController,    :index
    post "/login",                                          LoginController,    :login
    get  "/logout",                                         LoginController,    :logout
  end

  # Other scopes may use custom stacks.
  # scope "/api", Incunabula do
  #   pipe_through :api
  # end
end
