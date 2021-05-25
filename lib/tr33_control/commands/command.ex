defmodule Tr33Control.Commands.Command do
  use Ecto.Schema

  alias Protobuf.Field
  alias Tr33Control.Commands.Schemas.CommandParams

  @primary_key false
  embedded_schema do
    # internal
    field :index, :integer, default: 0
    field :targets, {:array, Tr33Control.Atom}, default: Application.compile_env!(:tr33_control, :command_targets)

    # protobuf
    field :params, :map
    field :encoded, :binary
  end

  def new(index, type) when is_atom(type) do
    %Protobuf.OneOfField{fields: fields} = CommandParams.defs(:field, :type_params)
    %Field{type: {:msg, type_struct}} = Enum.find(fields, &match?(%Field{name: ^type}, &1))
    type_message = apply(type_struct, :new, [])

    %__MODULE__{
      index: index,
      params: CommandParams.new(index: index, type_params: {type, type_message})
    }
    |> encode()
  end

  def disabled(index) do
    %__MODULE__{
      index: index,
      params: CommandParams.new(index: index, disabled: true)
    }
    |> encode()
  end

  def encode(%__MODULE__{params: %{__struct__: type} = msg} = command) do
    encoded = apply(type, :encode, [msg])
    %__MODULE__{command | encoded: encoded}
  end

  def get_field_def(name) when is_atom(name) do
    CommandParams.defs(:field, name)
  end

  def list_type_field_defs(%__MODULE__{params: %CommandParams{type_params: {_, type_params}}}) do
    type_params
    |> Map.from_struct()
    |> Map.keys()
    |> Enum.map(&apply(type_params.__struct__, :defs, [:field, &1]))
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1.fnum)
  end

  def type(%__MODULE__{params: %CommandParams{type_params: {type, _}}}), do: type
  def type_params(%__MODULE__{params: %CommandParams{type_params: {_, type_params}}}), do: type_params
end
