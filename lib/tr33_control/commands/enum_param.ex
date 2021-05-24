defmodule Tr33Control.Commands.EnumParam do
  alias Protobuf.Field
  alias Tr33Control.Commands.Command
  alias Tr33Control.Commands.Schemas.CommonParams

  @enforce_keys [:name, :options]
  defstruct [:value, :name, :options]

  def new(struct, %Field{type: {:enum, type}} = field_def) when is_struct(struct) do
    %__MODULE__{
      name: field_def.name,
      value: Map.fetch!(struct, field_def.name),
      options: apply(type, :atoms, [])
    }
  end

  def new(_, _), do: nil
  # def get_common(%Command{params: %{common: %CommonParams{} = common}}, name) when is_atom(name) do
  #   Command.list_common_params()
  #   |> Enum.find(&match?(%{type: {:enum, _}, name: ^name}, &1))
  #   |> then(fn %{name: name, type: {:enum, type}} ->
  #     %__MODULE__{
  #       name: name,
  #       value: Map.fetch!(common, name),
  #       options: apply(type, :atoms, [])
  #     }
  #   end)
  # end

  # def list(%Command{params: params} = command) do
  #   Command.list_params(command)
  #   |> Enum.filter(&match?(%{type: {:enum, _}}, &1))
  #   |> Enum.map(fn %{name: name, type: {:enum, type}} ->
  #     %__MODULE__{
  #       name: name,
  #       value: Map.fetch!(params, name),
  #       options: apply(type, :atoms, [])
  #     }
  #   end)
  # end
end
