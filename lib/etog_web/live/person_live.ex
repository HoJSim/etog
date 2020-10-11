defmodule EtogWeb.PersonLive do
  @moduledoc false

  alias Etog.N4j
  alias Etog.N4j.Result
  alias EtogWeb.Helpers.LocaleSelector

  import EtogWeb.Gettext, only: [gettext: 1]
  import EtogWeb.Helpers.LiveHelpers

  use Phoenix.LiveView, layout: {EtogWeb.LayoutView, "live.html"}

  @impl true
  def render(assigns) do
    Phoenix.View.render(EtogWeb.PersonView, "#{assigns[:tmpl]}.html", assigns)
  end

  @impl true
  def mount(params, session, socket) do
    if session["locale"] do
      Gettext.put_locale(EtogWeb.Gettext, session["locale"])
    end

    {tmpl, active_link} =
      if session["tmpl"] == "resume" do
        {"resume", :resume}
      else
        {"index", :home}
      end

    state = %{
      tmpl: tmpl,
      active_link: active_link,
      pid: nil,
      locale: Gettext.get_locale(EtogWeb.Gettext),
      person: nil,
      nodes: [],
      edges: [],
      page_title: page_title(socket),
      selected_note: nil
    }

    socket = assign(socket, state)

    socket =
      case N4j.start([self()]) do
        {:ok, pid} ->
          assign(socket, :pid, pid)

        _ ->
          put_flash(socket, :error, gettext("Cannot load data from the database. Try to reload the page."))
      end

    user_id = params["id"] || Application.get_env(:etog, EtogWeb.Endpoint)[:default_person]
    pid = socket.assigns[:pid]

    socket =
      if connected?(socket) do
        load_person(pid, user_id)
        socket
      else
        init_prepare_page(socket, pid, user_id)
      end

    {:ok, socket}
  end

  @impl true
  def handle_info({:person, %Result{} = result}, socket) do
    {:noreply, prepare_person(result, socket)}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  defp prepare_person(%Result{} = result, socket) do
    if Enum.empty?(result.errors) do
      cond do
        is_nil(result.nodes) ->
          show_errors(socket, gettext("The person wasn't found. Something went wrong."))

        Enum.empty?(result.nodes) ->
          show_errors(socket, gettext("The person wasn't found. Check thay you write the correct name."))

        true ->
          person = Enum.find(result.nodes, &(&1.id == result.head))

          nodes =
            Enum.reject(result.nodes, &(&1.id == result.head))
            |> list_to_map

          edges = list_to_map(result.edges)

          assign(socket, %{
            page_title: page_title(socket, person),
            person: person,
            nodes: nodes,
            edges: edges
          })
      end
    else
      show_errors(socket, result.errors)
    end
  end

  defp page_title(socket, person \\ nil) do
    title =
      if person do
        LocaleSelector.l(socket.assigns[:locale], person.props["name"])
      else
        Application.get_env(:etog, EtogWeb.Endpoint)[:title]
      end

    page =
      if socket.assigns[:tmpl] == "resume" do
        gettext("Resume")
      else
        gettext("Personal blog")
      end

    "#{title} - #{page}"
  end

  defp load_person(pid, key, async \\ true) do
    N4j.find_by(
      pid,
      [
        %{
          statement: "MATCH (pe:Person {key: $key}) RETURN pe",
          parameters: %{key: key}
        },
        %{
          statement: "MATCH (pe:Person {key: $key})
                      MATCH (pe)-[lin:LIVE_IN]->(city:City)-[loc_in:LOCATED_IN]->(country)
                      RETURN lin,city,loc_in,country",
          parameters: %{key: key}
        },
        %{
          statement: "MATCH (pe:Person {key: $key})
                      MATCH (pe)-[sat:STUDIED_AT]->(f:Faculty)-[fr:BELONGS_TO]->(u) RETURN sat,f,fr,u",
          parameters: %{key: key}
        },
        %{
          statement: "MATCH (pe:Person {key: $key})
                      MATCH (pe)-[pin:PARTICIPATED_IN]->(e:Event)-[linked:LINKED_WITH]->(f) RETURN pin,e,linked,f",
          parameters: %{key: key}
        },
        %{
          statement: "MATCH (pe:Person {key: $key})
                      MATCH (pe)-[wat:WORKED_AT]->(o)-[oin:LOCATED_IN]->(j_city:City)-[j_loc_in:LOCATED_IN]->(j_country)
                      RETURN wat,o,oin,j_city,j_loc_in,j_country",
          parameters: %{key: key}
        },
        %{
          statement: "MATCH (pe:Person {key: $key})
                      MATCH (pe)-[kn:KNOW]->(s) RETURN kn,s",
          parameters: %{key: key}
        },
        %{
          statement: "MATCH (pe:Person {key: $key})
                      MATCH (pe)-[iin:INTERESTED_IN]->(int) RETURN iin,int",
          parameters: %{key: key}
        }
      ],
      :person,
      async
    )
  end

  defp init_prepare_page(socket, pid, user_id) do
    person = load_person(pid, user_id, false)
    prepare_person(person, socket)
  end
end
