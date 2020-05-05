defmodule EtogWeb.NotesView do
  use EtogWeb, :view

  alias EtogWeb.SharedView

  import EtogWeb.Helpers.LocaleSelector
  import Earmark, only: [as_html!: 1]

  def note_url_title(id, title) do
    title =
      title
      |> String.replace(" ", "-")
      |> URI.encode()

    "#{id}-#{title}"
  end

  def noted_at(note) do
    note.props["created_at"]
    |> String.slice(0, 10)
  end

  def split_source(source) do
    if String.starts_with?(source, ":") do
      source
      |> String.slice(1..-1)
      |> String.split(":", parts: 2)
    else
      [source, source]
    end
  end
end
