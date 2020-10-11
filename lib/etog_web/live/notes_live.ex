defmodule EtogWeb.NotesLive do
  @moduledoc false

  alias Etog.N4j
  alias Etog.N4j.Result
  alias EtogWeb.Helpers.LocaleSelector

  import Etog.N4j.Node, only: [build_relations: 4]
  import EtogWeb.Gettext, only: [gettext: 1]
  import EtogWeb.Helpers.LiveHelpers

  use Phoenix.LiveView, layout: {EtogWeb.LayoutView, "live.html"}

  @limit_notes 10

  @impl true
  def render(assigns) do
    Phoenix.View.render(EtogWeb.NotesView, "index.html", assigns)
  end

  @impl true
  def mount(params, session, socket) do
    if session["locale"] do
      Gettext.put_locale(EtogWeb.Gettext, session["locale"])
    end

    socket =
      assign(socket, %{
        locale: Gettext.get_locale(EtogWeb.Gettext),
        active_link: :notes,
        page_title: page_title(socket),
        preview_mode: preview_mode?(params),
        person: nil,
        notes: [],
        selected_note: nil,
        user_id: params["user_id"] || Application.get_env(:etog, EtogWeb.Endpoint)[:default_person],
        page: 0,
        last_page: true
      })

    socket =
      case N4j.start([self()]) do
        {:ok, pid} ->
          socket
          |> assign(:pid, pid)
          |> preload_notes(params["id"])

        _ ->
          put_flash(socket, :error, gettext("Cannot load data from the database. Try to reload the page."))
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      cond do
        preview_mode?(params) && socket.assigns[:preview_mode] ->
          assign(socket, :selected_note, nil)

        preview_mode?(params) ->
          load_notes(socket, nil, false)
          |> prepare_notes(socket)
          |> assign(:selected_note, nil)

        socket.assigns[:preview_mode] ->
          id = extract_note_id(params["id"])

          {_, note, _} =
            Enum.find(socket.assigns.notes, fn {_, node, _} ->
              node.id == id
            end)

          assign(socket, :selected_note, note)

        true ->
          socket
          |> assign(:user_id, params["user_id"])
          |> load_notes(params["id"], false)
          |> prepare_notes(socket)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:notes, %Result{} = result}, socket) do
    {
      :noreply,
      prepare_notes(result, socket)
      |> assign(preview_mode: true)
    }
  end

  @impl true
  def handle_info({:note, %Result{} = result}, socket) do
    {:noreply, prepare_notes(result, socket)}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  defp extract_note_id(id) do
    id
    |> String.split("-", parts: 2)
    |> List.first()
    |> String.to_integer()
  end

  defp preview_mode?(params) do
    !(params["id"] && params["user_id"])
  end

  defp page_title(socket, person \\ nil) do
    base_title =
      if person do
        LocaleSelector.l(socket.assigns[:locale], person.props["name"])
      else
        Application.get_env(:etog, EtogWeb.Endpoint)[:title]
      end

    "#{base_title} - #{gettext("30 Second Notes")}"
  end

  defp prepare_notes(%Result{} = result, socket) do
    if Enum.empty?(result.errors) do
      cond do
        is_nil(result.nodes) ->
          show_errors(socket, gettext("Notes weren't found. Something went wrong."))

        Enum.empty?(result.nodes) ->
          show_errors(socket, gettext("There're not notes."))

        true ->
          parse_notes(socket, result)
      end
    else
      show_errors(socket, result.errors)
    end
  end

  defp parse_notes(socket, result) do
    person = Enum.find(result.nodes, &(&1.id == result.head))

    nodes =
      Enum.reject(result.nodes, &(&1.id == result.head))
      |> list_to_map

    edges = list_to_map(result.edges)
    notes = build_relations(person, nodes, edges, {"MAKE", {"Note", nil}, nil})

    assign(socket, %{
      page_title: page_title(socket, person),
      person: person,
      notes: Enum.take(notes, @limit_notes),
      last_page: length(notes) <= @limit_notes,
      selected_note: if(socket.assigns[:preview_mode], do: nil, else: notes |> List.first() |> elem(1))
    })
  end

  defp preload_notes(socket, id) do
    if connected?(socket) do
      load_notes(socket, id)
      socket
    else
      load_notes(socket, id, false)
      |> prepare_notes(socket)
    end
  end

  defp load_notes(socket, id, async \\ true) do
    if id do
      fetch_note(socket, id, async)
    else
      fetch_previews(socket, async)
    end
  end

  defp fetch_previews(socket, async) do
    user_id = socket.assigns[:user_id]
    page = socket.assigns[:page]
    order = "ORDER BY n.pinned DESC, n.created_at"
    offset = "SKIP #{page * @limit_notes} LIMIT #{@limit_notes + 1}"

    N4j.find_by(
      socket.assigns[:pid],
      [
        %{
          statement: "MATCH (pe:Person {key: $key}) RETURN pe",
          parameters: %{key: user_id}
        },
        %{
          statement: "MATCH (pe:Person {key: $key})
                      MATCH (pe)-[r:MAKE]->(n:Note) RETURN r, n #{order} #{offset}",
          parameters: %{key: user_id}
        }
      ],
      :notes,
      async
    )
  end

  defp fetch_note(socket, id, async) do
    user_id = socket.assigns[:user_id]
    note_id = extract_note_id(id)

    N4j.find_by(
      socket.assigns[:pid],
      [
        %{
          statement: "MATCH (pe:Person {key: $key}) RETURN pe",
          parameters: %{key: user_id}
        },
        %{
          statement: "MATCH (pe:Person {key: $key})
                      MATCH (pe)-[r:MAKE]->(n:Note) WHERE id(n)=$note_id RETURN r, n",
          parameters: %{key: user_id, note_id: note_id}
        }
      ],
      :note,
      async
    )
  end
end
