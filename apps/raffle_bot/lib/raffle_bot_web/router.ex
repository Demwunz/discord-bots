defmodule RaffleBotWeb.Router do
  use RaffleBotWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", RaffleBotWeb do
    pipe_through :api
  end
end
