# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

secret_key_base = "E2JHw5yMe+7Swhe8wskPCq6J/WlCjt777d6dz85VZqe5ybBbL78+oTr3kWs9K3OJ"

config :tr33_control, Tr33ControlWeb.Endpoint, secret_key_base: secret_key_base

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :tr33_control, Tr33ControlWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
