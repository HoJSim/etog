defmodule Etog.N4j do
  @moduledoc false

  use GenServer

  alias Etog.N4j.Edge
  alias Etog.N4j.Node
  alias Etog.N4j.Result

  import EtogWeb.Gettext, only: [gettext: 1]

  def start(parent_pid) do
    GenServer.start_link(__MODULE__, parent_pid)
  end

  @impl true
  def init([parent_pid]) do
    state = %{
      pid: parent_pid
    }

    {:ok, state}
  end

  def find_by(pid, statements, tag \\ nil, async \\ true) do
    if async do
      GenServer.cast(pid, {:find_by, tag, statements})
    else
      GenServer.call(pid, {:find_by, statements})
    end
  end

  @impl true
  def handle_call({:find_by, statements}, _from, state) do
    query = %{
      statements: Enum.map(statements, &Map.put(&1, :resultDataContents, ["graph"]))
    }

    {:reply, execute(query), state}
  end

  @impl true
  def handle_cast({:find_by, tag, statements}, state) do
    query = %{
      statements: Enum.map(statements, &Map.put(&1, :resultDataContents, ["graph"]))
    }

    send(state[:pid], {tag, execute(query)})

    {:noreply, state}
  end

  defp execute(query) do
    conf = Application.get_env(:etog, EtogWeb.Endpoint)[:db]

    HTTPoison.post(
      "#{conf[:url]}/tx/commit",
      Jason.encode!(query),
      [
        {"Authorization", "Basic " <> Base.encode64(conf[:user] <> ":" <> conf[:pass])},
        {"Content-Type", "application/json"}
      ]
    )
    |> convert
  end

  defp parse_nodes(result, nodes) do
    result
    |> Map.put(
      :nodes,
      nodes
      |> Enum.reduce(result[:nodes], fn node, acc ->
        id = String.to_integer(node["id"])
        node_inst = acc[id]

        if node_inst do
          acc
        else
          acc
          |> Map.put(id, %{
            id: id,
            labels: node["labels"],
            props: node["properties"],
            edges: []
          })
        end
      end)
    )
  end

  defp parse_edges(result, edges) do
    edges
    |> Enum.reduce(result, fn edge, acc ->
      id = String.to_integer(edge["id"])
      edge_inst = acc[:edges][id]

      if edge_inst do
        acc
      else
        node_id = String.to_integer(edge["startNode"])
        edges = [%{id: id, type: edge["type"]} | acc[:nodes][node_id][:edges]]

        acc
        |> put_in([:nodes, node_id, :edges], edges)
        |> put_in([:edges, id], %{
          id: id,
          type: edge["type"],
          props: edge["properties"],
          node_id: String.to_integer(edge["endNode"])
        })
      end
    end)
  end

  defp parse_statement_row(row, result) do
    result
    |> parse_nodes(row["graph"]["nodes"])
    |> parse_edges(row["graph"]["relationships"])
  end

  defp parse_statement(statement, result) do
    statement["data"]
    |> Enum.reduce(result, &parse_statement_row/2)
  end

  defp eval_head(results) do
    nodes =
      results
      |> List.first()
      |> get_in(["data"])
      |> List.first()
      |> get_in(["graph", "nodes"])
    if nodes do
      nodes
      |> List.first()
      |> get_in(["id"])
      |> String.to_integer()
    end
  end

  defp convert(result) do
    case result do
      {:ok, response} ->
        body = Jason.decode!(response.body)

        %{nodes: nodes, edges: edges} = Enum.reduce(body["results"], %{nodes: %{}, edges: %{}}, &parse_statement/2)

        %Result{
          head: eval_head(body["results"]),
          nodes: Enum.map(Map.values(nodes), &struct(Node, &1)),
          edges: Enum.map(Map.values(edges), &struct(Edge, &1)),
          errors: body["errors"]
        }

      _ ->
        %Result{errors: [%{"code" => "N4j.UnexeptedError", "message" => gettext("Unexepted Error")}]}
    end
  end
end
