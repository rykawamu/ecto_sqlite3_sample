defmodule TeckFanzineWeb.PageController do
  use TeckFanzineWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
