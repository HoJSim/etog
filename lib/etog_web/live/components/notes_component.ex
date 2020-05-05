defmodule EtogWeb.Components.NotesComponent do
  @moduledoc false

  use Phoenix.LiveComponent

  @impl true
  def render(assigns) do
    Phoenix.View.render(EtogWeb.Components.NotesView, "index.html", assigns)
  end
end
