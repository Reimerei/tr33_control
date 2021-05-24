defmodule Tr33Control.Commands.Command do
  use Ecto.Schema

  alias Tr33Control.Commands
  alias Tr33Control.Commands.Schemas

  @primary_key false
  embedded_schema do
    # internal
    field :index, :integer, default: 0
    field :enabled, :boolean, default: true
    field :targets, {:array, Tr33Control.Atom}, default: Application.compile_env!(:tr33_control, :command_targets)

    # protobuf
    field :params, :map
    field :encoded, :binary
  end

  def encode(%__MODULE__{params: %{__struct__: type} = msg} = command) do
    encoded = apply(type, :encode, [msg])
    %__MODULE__{command | encoded: encoded}
  end

  def get_common_field_def(name) when is_atom(name) do
    Schemas.CommonParams.defs(:field, name)
  end

  def list_field_defs(%__MODULE__{params: params}) do
    params
    |> field_defs_from_struct()
  end

  defp field_defs_from_struct(%{__struct__: type} = struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:common])
    |> Map.keys()
    |> Enum.map(&apply(type, :defs, [:field, &1]))
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1.fnum)
  end
end
