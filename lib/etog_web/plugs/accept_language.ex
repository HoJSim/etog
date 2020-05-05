defmodule EtogWeb.Plugs.AcceptLanguage do
  @moduledoc "set locale from cookies or an accept-language header"

  import Plug.Conn

  @language_header "accept-language"
  @language_cookie "locale"
  @locales ["en", "ru"]

  def init(default), do: default

  def call(conn, _default) do
    locale = conn.cookies[@language_cookie] || get_header_locale(conn)

    if locale in @locales do
      Gettext.put_locale(EtogWeb.Gettext, locale)
      set_session_locale(conn, locale)
    else
      conn
    end
  end

  defp set_session_locale(conn, locale) do
    if get_session(conn, "locale") != locale do
      conn
      |> put_session("locale", locale)
    else
      conn
    end
  end

  defp get_header_locale(conn) do
    val =
      case get_req_header(conn, @language_header) do
        [header] -> header
        [header | _] -> header
        _ -> ""
      end

    val
    |> String.split(";")
    |> List.first()
    |> String.split(",")
    |> List.first()
    |> String.slice(0, 2)
  end
end
