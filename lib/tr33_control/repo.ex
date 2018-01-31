defmodule Tr33Control.Repo do
  use Ecto.Repo, otp_app: :tr33_control

  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end
