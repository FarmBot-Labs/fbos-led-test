defmodule HelloLedsWeb.PageController do
  use HelloLedsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
