defmodule EtogWeb.PersonView do
  use EtogWeb, :view

  alias EtogWeb.SharedView

  import EtogWeb.Helpers.LocaleSelector
  import EtogWeb.Helpers.Datetime
  import Earmark, only: [as_html!: 1]
  import Etog.N4j.Node, only: [build_relations: 4, sort_relations_by: 3]

  @lang_levels {nil, "A1", "A2", "B1", "B2", "C1", "C2", "native"}

  def location(person, nodes, edges) do
    build_relations(person, nodes, edges, {"LIVE_IN", nil, {"LOCATED_IN", nil, nil}})
  end

  def responsibilities(props, locale) do
    l(locale, props["responsibilities"])
    |> Jason.decode!()
  end

  def jobs(person, nodes, edges) do
    build_relations(person, nodes, edges, {"WORKED_AT", nil, {"LOCATED_IN", nil, {"LOCATED_IN", nil, nil}}})
    |> sort_relations_by(
      fn {j_edge, _, _} ->
        j_edge.props["from"]
      end,
      &>/2
    )
  end

  def degrees(person, nodes, edges) do
    build_relations(person, nodes, edges, {"STUDIED_AT", nil, {"BELONGS_TO", nil, nil}})
  end

  def university_activities(person, nodes, edges, faculty_id) do
    build_relations(
      person,
      nodes,
      edges,
      {"PARTICIPATED_IN", {"Event", nil}, {"LINKED_WITH", {"Faculty", %{"id" => faculty_id}}, nil}}
    )
  end

  def list_of_skills(person, nodes, edges, locale) do
    (skills(person, nodes, edges, "hard skills") ++ skills(person, nodes, edges, "soft skills"))
    |> Enum.map(fn {_, node, _} ->
      l(locale, node.props["title"])
    end)
  end

  def skills(person, nodes, edges, skill_type) do
    build_relations(person, nodes, edges, {"KNOW", {"Skill", %{"type" => skill_type}}, nil})
    |> sort_relations_by(
      fn {_, node, _} ->
        node.props["weight"]
      end,
      &<=/2
    )
  end

  def languages(person, nodes, edges) do
    build_relations(person, nodes, edges, {"KNOW", {"Skill", %{"type" => "languages"}}, nil})
    |> sort_relations_by(
      fn {_, node, _} ->
        node.props["level"]
      end,
      &>/2
    )
  end

  def lang_level(node) do
    level = elem(@lang_levels, node.props["level"])
    if level, do: " (#{level})", else: ""
  end

  def list_of_interests(person, nodes, edges, locale) do
    interests(person, nodes, edges)
    |> Enum.map(fn {_, node, _} ->
      l(locale, node.props["title"])
    end)
  end

  def interests(person, nodes, edges) do
    build_relations(person, nodes, edges, {"INTERESTED_IN", nil, nil})
  end

  def contact_icon(contact) do
    %{
      "t.me" => "telegram",
      "github.com" => "github",
      "twitter.com" => "twitter"
    }[URI.parse(contact).host]
  end

  def contact_title(contact) do
    host = URI.parse(contact).host

    %{
      "t.me" => "telegram",
      "github.com" => "github",
      "twitter.com" => "twitter"
    }[host] || host
  end

  def trips_stat(person, nodes, edges) do
    query = {"PARTICIPATED_IN", {"Trip", nil}, {"TRAVELLED_TO", nil, {"LOCATED_IN", nil, nil}}}
    trips = build_relations(person, nodes, edges, query)
    cities = visited_cities(trips)
    countries = visited_countries(cities)

    %{
      "visited_cities" => length(cities),
      "visited_countries" => length(countries),
      "duration" => Enum.reduce(countries, 0, fn details, total -> details[:nights] + total end)
    }
  end

  defp visited_cities(trips) do
    Enum.reduce(trips, %{}, fn {_, trip, [{_, city, [{_, country, _}]}]}, cities ->
      city_title = List.first(city.props["title"])
      country_title = List.first(country.props["title"])
      key = "#{country_title}, #{city_title}"
      nights = get_in(cities, [key, :nights]) || 0

      details = %{
        title: city.props["title"],
        country: country.props["title"],
        nights: nights + (trip.props["nights"] || 0)
      }

      Map.put(cities, key, details)
    end)
    |> Map.values()
  end

  defp visited_countries(cities) do
    Enum.reduce(cities, %{}, fn %{country: country, nights: nights}, countries ->
      key = List.first(country)
      prev_nights = get_in(countries, [key, :nights]) || 0

      details = %{
        title: country,
        nights: prev_nights + nights
      }

      Map.put(countries, key, details)
    end)
    |> Map.values()
  end
end
