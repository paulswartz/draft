defmodule DraftWeb.PageController do
  use DraftWeb, :controller

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _params) do
   render(conn, "index.html")
  end
end
