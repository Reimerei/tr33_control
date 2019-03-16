defmodule Mix.Tasks.GravityProfile do
  use Mix.Task

  def run([file]) do
    File.read!(file)
    |> String.split(" ")
    |> Enum.map(&parse_point/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_point(str) do
    case String.split(str, ",") do
      [x_str, y_str] ->
        {x, _} = Integer.parse(x_str)
        {y, _} = Integer.parse(y_str)
        {x, y} |> IO.inspect(label: "parsed")

      [""] ->
        :noop

      other ->
        IO.inspect(other, label: "skipped")
        nil
    end
  end
end
