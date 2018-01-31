defmodule Tr33Control.Commands.HexBinary do
  @behaviour Ecto.Type
  def type, do: :binary

  @data_bytes 64

  def cast(string) when is_bitstring(string) do
    with {:ok, data} <- Base.decode16(string, case: :mixed) do
      {:ok, pad_data(data)}
    end
  end

  def load(data) do
    {:ok, data}
  end

  def dump(data) when is_binary(data), do: {:ok, data}
  def dump(_), do: :error

  defp pad_data(data) do
    pad_length = (@data_bytes - byte_size(data)) * 8
    <<data::binary, 0::size(pad_length)>>
  end
end
