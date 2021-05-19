defmodule Tr33Control.Commands.Command do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    # internal
    field :index, :integer, default: 0
    field :enabled, :boolean, default: true
    field :targets, {:array, Tr33Control.Atom}, default: Application.fetch_env!(:tr33_control, :command_targets)

    # protobuf
    field :message, :map
    field :encoded, :binary
  end

  def encode(%__MODULE__{message: %{__struct__: type} = msg} = command) do
    encoded = apply(type, :encode, [msg])
    %__MODULE__{command | encoded: encoded}
  end
end
