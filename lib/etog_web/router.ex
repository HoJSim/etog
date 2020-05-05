defmodule EtogWeb.Router do
  use EtogWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {EtogWeb.LayoutView, :root}
    plug EtogWeb.Plugs.AcceptLanguage
    plug EtogWeb.Plugs.AcceptScheme
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EtogWeb do
    pipe_through :browser

    live "/30-sec-notes/:user_id/:id", NotesLive, :show, container: {:div, class: "page"}
    live "/30-sec-notes", NotesLive, container: {:div, class: "page"}

    live "/about-project", AboutLive, container: {:div, class: "page"}

    live "/resume", PersonLive, :resume, container: {:div, class: "page"}, session: %{"tmpl" => "resume"}
    live "/:id/resume", PersonLive, :resume, container: {:div, class: "page"}, session: %{"tmpl" => "resume"}
    live "/:id", PersonLive, :show, container: {:div, class: "page"}
    live "/", PersonLive, container: {:div, class: "page"}

    live_dashboard "/dashboard"
  end
end
