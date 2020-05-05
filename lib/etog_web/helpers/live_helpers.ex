defmodule EtogWeb.Helpers.LiveHelpers do
  @moduledoc false

  import Phoenix.LiveView, only: [put_flash: 3]

  def list_to_map(collection),
    do: Enum.reduce(collection, %{}, fn item, acc -> Map.put(acc, item.id, item) end)

  def show_errors(socket, errors) when is_list(errors) do
    msg =
      errors
      |> Enum.map(& &1["message"])
      |> Enum.join("\n")

    put_flash(socket, :error, msg)
  end

  def show_errors(socket, msg),
    do: put_flash(socket, :error, msg)
end
