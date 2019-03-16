defmodule Tr33ControlWeb.Router do
  use Tr33ControlWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", Tr33ControlWeb do
    pipe_through :browser

    get "/", CommandsController, :index
    get "/docs", DocsController, :index
  end
end
