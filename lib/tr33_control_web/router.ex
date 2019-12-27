defmodule Tr33ControlWeb.Router do
  use Tr33ControlWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_layout, {Tr33ControlWeb.LayoutView, :app}
  end

  scope "/", Tr33ControlWeb do
    pipe_through :browser

    live "/", IndexLive
    live "/twang", TwangLive
    get "/docs", DocsController, :index
  end
end
