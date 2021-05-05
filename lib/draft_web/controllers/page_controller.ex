defmodule DraftWeb.PageController do
  use DraftWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
