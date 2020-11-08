defmodule Tr33Control.Commands.Cache do
  require Logger
  alias Tr33Control.Commands
  alias Tr33Control.Commands.{Command, Event, Preset, Modifier}

  @all_cache_keys [Command, Event, Preset]

  def init_all() do
    Enum.map(@all_cache_keys, &init/1)
  end

  def init(Command) do
    0..Application.fetch_env!(:tr33_control, :command_max_index)
    |> Enum.map(&Command.defaults/1)
    |> Enum.map(&insert(&1, true))
  end

  def init(Event) do
    [
      %Event{type: :update_settings}
    ]
    |> Enum.map(&Event.defaults/1)
    |> Enum.map(&insert(&1, true))
  end

  def init(Preset) do
    if File.exists?(presets_persist_file()) do
      Logger.info("Loading persisted presets from #{inspect(presets_persist_file())}")
      File.read!(presets_persist_file()) |> :erlang.binary_to_term()
      Cachex.load!(Preset, presets_persist_file())
      Enum.map(@all_cache_keys, &migrate/1)
    else
      Logger.warn("No preset persist file found #{inspect(presets_persist_file())}")
    end
  end

  def clear_all() do
    Enum.map(@all_cache_keys, &clear/1)
  end

  def clear(key) do
    Cachex.clear!(key)
  end

  def insert(%{__struct__: cache} = struct, force) when cache in @all_cache_keys do
    Cachex.put!(cache, cache_key(struct), struct)
    maybe_persist_cache(struct)
    Commands.notify_subscribers({cache, cache_key(struct)}, force)
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

  def delete(cache, key) when cache in @all_cache_keys do
    res = Cachex.take(cache, key)
    Commands.notify_subscribers({cache, key}, true)
    res
  end

  defp cache_key(%Command{index: index}), do: index
  defp cache_key(%Event{type: type}), do: type
  defp cache_key(%Preset{name: name}), do: name

  defp maybe_persist_cache(%Preset{}), do: Cachex.dump!(Preset, presets_persist_file())
  defp maybe_persist_cache(_), do: :noop

  defp presets_persist_file() do
    Application.fetch_env!(:tr33_control, :cache_persist_dir) |> Path.join("presets.bin")
  end

  defp migrate(Preset = cache) do
    all(cache)
    |> Enum.map(&struct!(Preset, Map.delete(&1, :__struct__)))
    |> Enum.map(fn %Preset{commands: commands} = preset ->
      commands =
        commands
        |> Enum.map(&struct!(Command, Map.delete(&1, :__struct__)))
        |> Enum.map(&migrate_modifiers_to_map/1)
        |> Enum.map(&migrate_target/1)

      %Preset{preset | commands: commands}
    end)
    |> Enum.map(&insert(&1, false))
  end

  defp migrate(_), do: :noop

  defp migrate_modifiers_to_map(%Command{modifiers: %{}} = command), do: command
  defp migrate_modifiers_to_map(%Command{modifiers: nil} = command), do: command

  defp migrate_modifiers_to_map(%Command{modifiers: modifiers} = command) when is_list(modifiers) do
    map =
      modifiers
      |> Enum.map(fn %{field_index: field_index} = modifier ->
        {field_index, struct!(Modifier, Map.drop(modifier, [:__struct__, :field_index]))}
      end)
      |> Enum.into(%{})

    %Command{command | modifiers: map}
  end

  defp migrate_target(%Command{target: "all"} = command), do: %Command{command | target: :all}
  defp migrate_target(%Command{target: nil} = command), do: %Command{command | target: :all}
  defp migrate_target(%Command{} = command), do: command
end
