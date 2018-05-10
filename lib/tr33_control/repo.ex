defmodule Tr33Control.Repo do
  use Ecto.Repo, otp_app: :tr33_control, adapter: Sqlite.Ecto2
end
