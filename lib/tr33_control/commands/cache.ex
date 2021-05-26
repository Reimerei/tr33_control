defmodule Tr33Control.Commands.Cache do
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Event, Preset, Modifier}

  @all_cache_keys [Command, Preset]

  def init_all() do
    Enum.map(@all_cache_keys, &init/1)
  end

  def init(Command) do
    Commands.create_command(0)
    Commands.update_command_param(0, :brightness, 0)

    Commands.create_command(1)
    Commands.update_command_param(1, :brightness, 0)
  end

  # todo
  # def init(Event) do
  #   [
  #     %Event{type: :update_settings}
  #   ]
  #   |> Enum.map(&Event.defaults/1)
  #   |> Enum.map(&insert(&1, true))
  # end

  # def init(Preset) do
  #   if File.exists?(presets_persist_file()) do
  #     Logger.info("Loading persisted presets from #{inspect(presets_persist_file())}")
  #     File.read!(presets_persist_file()) |> :erlang.binary_to_term()
  #     Cachex.load!(Preset, presets_persist_file())
  #     Enum.map(@all_cache_keys, &migrate/1)
  #   else
  #     Logger.warn("No preset persist file found #{inspect(presets_persist_file())}")
  #   end
  # end

  # def init(Modifier) do
  # end

  def clear_all() do
    Enum.map(@all_cache_keys, &clear/1)
  end

  def clear(key) do
    Cachex.clear!(key)
  end

  def insert(%{__struct__: cache} = struct) when cache in @all_cache_keys do
    Cachex.put!(cache, cache_key(struct), struct)
    maybe_persist_cache(struct)
    struct
  end

  def get(cache, key) when cache in @all_cache_keys do
    Cachex.get!(cache, key)
  end

  def all(cache) when cache in @all_cache_keys do
    query = Cachex.Query.create(true, :value)

    cache
    |> Cachex.stream!(query)
    |> Enum.into([])
  end

  def count(cache) when cache in @all_cache_keys do
    Cachex.count!(cache)
  end

  def delete(cache, key) when cache in @all_cache_keys do
    res = Cachex.take(cache, key)
    res
  end

  defp cache_key(%Command{index: index}), do: index
  defp cache_key(%Event{type: type}), do: type
  defp cache_key(%Preset{name: name}), do: name
  defp cache_key(%Modifier{index: index, data_index: data_index}), do: {index, data_index}

  defp maybe_persist_cache(%Preset{}), do: Cachex.dump!(Preset, presets_persist_file())
  defp maybe_persist_cache(_), do: :noop

  defp presets_persist_file() do
    Application.fetch_env!(:tr33_control, :cache_persist_dir) |> Path.join("presets.bin")
  end

  # todo
  # defp migrate(Preset = cache) do
  #   all(cache)
  #   |> Enum.map(&struct!(Preset, Map.delete(&1, :__struct__)))
  #   |> Enum.map(fn %Preset{commands: commands} = preset ->
  #     commands =
  #       commands
  #       |> Enum.map(&struct!(Command, Map.drop(&1, [:__struct__, :modifiers])))
  #       |> Enum.map(&migrate_target/1)

  #     %Preset{preset | commands: commands}
  #   end)
  #   |> Enum.map(&insert(&1, false))
  # end

  # defp migrate(_), do: :noop

  # defp migrate_target(%Command{target: "all"} = command), do: %Command{command | target: :all}
  # defp migrate_target(%Command{target: nil} = command), do: %Command{command | target: :all}
  # defp migrate_target(%Command{} = command), do: command
end
