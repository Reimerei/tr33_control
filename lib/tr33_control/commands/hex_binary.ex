defmodule Tr33Control.Commands.HexBinary do
  @behaviour Ecto.Type
  def type, do: :binary

  @data_bytes 64

  def cast(string) when is_bitstring(string) do
    string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
    |> to_binary
    |> pad
  rescue
    _ -> :error
  end

  def load(data) do
    {:ok, data}
  end

  def dump(data) when is_binary(data), do: {:ok, data}
  def dump(_), do: :error

  defp to_binary([x | rest]) when x <= 255, do: <<x::integer-size(8), to_binary(rest)::binary>>
  defp to_binary([]), do: <<>>

  defp pad(data) when is_binary(data) do
    pad_length = (@data_bytes - byte_size(data)) * 8
    {:ok, <<data::binary, 0::size(pad_length)>>}
  end
end
