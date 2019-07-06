defmodule Tr33Control.Commands.Modifier do
  use Ecto.Schema

  alias Ecto.Changeset

  embedded_schema do
    field :period, :integer
    field :offset, :integer
  end

  def defaults(%__MODULE__{} = modifier \\ %__MODULE__{}) do
    %__MODULE__{modifier | period: 3_000, offset: 0}
  end

  def change(modifier, params) do
    modifier
    |> Changeset.cast(params, [:period, :offset])
  end
end
