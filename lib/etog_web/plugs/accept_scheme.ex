defmodule EtogWeb.Plugs.AcceptScheme do
  @moduledoc "set locale from cookies or an accept-language header"

  import Plug.Conn

  @scheme_cookie "color-scheme"
  @schemes ["light", "dark"]

  def init(default), do: default

  def call(conn, _default) do
    scheme = conn.cookies[@scheme_cookie]

    if scheme in @schemes do
      set_session_scheme(conn, scheme)
    else
      conn
    end
  end

  defp set_session_scheme(conn, scheme) do
    if get_session(conn, "color_scheme") != scheme do
      conn
      |> put_session("color_scheme", scheme)
    else
      conn
    end
  end
end
