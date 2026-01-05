defmodule CronusWeb.PageController do
  use CronusWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
