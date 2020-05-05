defmodule EtogWeb.AboutLive do
  @moduledoc false

  import EtogWeb.Gettext, only: [gettext: 1]

  use Phoenix.LiveView, layout: {EtogWeb.LayoutView, "live.html"}

  @impl true
  def render(assigns) do
    Phoenix.View.render(EtogWeb.AboutView, "index.html", assigns)
  end

  @impl true
  def mount(_params, session, socket) do
    if session["locale"] do
      Gettext.put_locale(EtogWeb.Gettext, session["locale"])
    end

    state = %{
      active_link: :about,
      locale: Gettext.get_locale(EtogWeb.Gettext),
      page_title: Application.get_env(:etog, EtogWeb.Endpoint)[:title] <> ": " <> gettext("about project")
    }

    {:ok, assign(socket, state)}
  end
end
