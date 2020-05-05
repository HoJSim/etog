defmodule EtogWeb.Helpers.LocaleSelector do
  @moduledoc false

  def l(locale, data) when is_list(data) do
    List.to_tuple(data)
    |> elem(eval_idx(locale))
  end

  def l(locale, data) when is_tuple(data) do
    elem(data, eval_idx(locale))
  end

  def l(_locale, data), do: data

  defp eval_idx(locale) do
    Application.get_env(:etog, EtogWeb.Endpoint)[:locales][locale] || 0
  end
end
