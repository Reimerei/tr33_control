defmodule Tr33Control.Application do
  use Application
  alias Tr33Control.Commands

  def start(_type, _args) do
    setup_db!()

    children = [
      Tr33Control.Repo,
      Tr33ControlWeb.Endpoint,
      Tr33Control.Commands.UART,
      Tr33Control.Commands.UdpServer,
      Tr33Control.Joystick
      # Tr33Control.Commands.Socket
    ]

    opts = [strategy: :one_for_one, name: Tr33Control.Supervisor]
    sup = Supervisor.start_link(children, opts)

    Commands.init()

    sup
  end

  def config_change(changed, _new, removed) do
    Tr33ControlWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp setup_db!() do
    [repo] = Application.fetch_env!(:tr33_control, :ecto_repos)

    setup_repo!(repo)
    migrate_repo!(repo)
  end

  defp setup_repo!(repo) do
    db_file = Application.fetch_env!(:tr33_control, repo)[:database]

    unless File.exists?(db_file) do
      :ok = repo.__adapter__.storage_up(repo.config)
    end
  end

  defp migrate_repo!(repo) do
    opts = [all: true]
    {:ok, pid, apps} = Mix.Ecto.ensure_started(repo, opts)

    migrations_path = Path.join([:code.priv_dir(:tr33_control), "repo", "migrations"])
    migrated = Ecto.Migrator.run(repo, migrations_path, :up, all: true)

    repo.stop(pid)
    Mix.Ecto.restart_apps_if_migrated(apps, migrated)
  end
end
