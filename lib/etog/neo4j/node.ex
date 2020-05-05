defmodule Etog.N4j.Node do
  @moduledoc false

  defstruct [:edges, :id, :labels, :props]

  # link(head, nodes, edges, {"STUDIED_AT", nil, {"BELONGS_TO", nil, nil}})
  # link(
  #   head,
  #   nodes,
  #   edges,
  #   {"PARTICIPATED_IN", {"Trip", nil}, {"TRAVELLED_TO", {"City", nil}, {"LOCATED_IN", {"Country", nil}, nil}}})
  def build_relations(_head, _nodes, _edges, nil), do: []

  def build_relations(head, nodes, edges, {type, filters, includes}) do
    Enum.filter(head.edges, fn edge_attrs ->
      edge_attrs[:type] == type
    end)
    |> Enum.map(fn edge_attrs ->
      edge = edges[edge_attrs[:id]]
      node = edge && nodes[edge.node_id]

      if suitable_node?(node, filters) do
        {edge, node, build_relations(node, nodes, edges, includes)}
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def sort_relations_by(nodes, mapper, sorter) do
    Enum.sort_by(nodes, mapper, sorter)
  end

  defp suitable_node?(nil, _),
    do: false

  defp suitable_node?(_node, nil),
    do: true

  defp suitable_node?(node, filters) do
    suitable_node_type?(node, elem(filters, 0)) &&
      suitable_node_props?(node, elem(filters, 1))
  end

  defp suitable_node_type?(_node, nil),
    do: true

  defp suitable_node_type?(node, label),
    do: label in node.labels

  defp suitable_node_props?(_node, nil),
    do: true

  defp suitable_node_props?(node, props) do
    Enum.all?(props, fn {k, v} ->
      (k == "id" && node.id == v) || node.props[k] == v
    end)
  end
end
