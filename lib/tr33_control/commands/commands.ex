defmodule Tr33Control.Commands do
  alias Tr33Control.Commands.{Command, Socket}

  def create_command(params) do
    %Command{}
    |> Command.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
  end

  def create_command!(index, type, data) do
    case create_command(%{index: index, type: type, data: data}) do
      {:ok, command} ->
        command

      {:error, %Ecto.Changeset{errors: errors}} ->
        raise RuntimeError, "Invalid parameters #{inspect(errors)}"
    end
  end

  def send_command(%Command{} = command) do
    command
    |> Socket.send_command()
  end

  def send_command(index, type, data) do
    create_command!(index, type, data)
    |> Socket.send_command()
  end

  def speed_test() do
    1..100
    |> Enum.map(fn n ->
      send_command(3, 1, Base.encode16(<< n >>))
      # :timer.sleep(20)
    end)
  end
end
