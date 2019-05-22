defmodule Tr33Control.Commands.Cache do
  require Logger
  alias Tr33Control.Commands.{Command, Event, Preset}

  @all_cache_keys [Command, Event, Preset]
  @presets_persist_file Application.fetch_env!(:tr33_control, :cache_persist_dir) |> Path.join("presets.bin")

  def init_all() do
    Enum.map(@all_cache_keys, &init/1)
  end

  def init(Command) do
    0..Application.fetch_env!(:tr33_control, :command_max_index)
    |> Enum.map(&Command.defaults/1)
    |> Enum.map(&insert/1)
  end

  def init(Event) do
    [
      %Event{type: :update_settings}
    ]
    |> Enum.map(&Event.defaults/1)
    |> Enum.map(&insert/1)
  end

  def init(Preset) do
    if File.exists?(@presets_persist_file) do
      Logger.info("Loading persisted presets from #{inspect(@presets_persist_file)}")
      File.read!(@presets_persist_file) |> :erlang.binary_to_term()
      Cachex.load!(Preset, @presets_persist_file)
    else
      Logger.warn("No preset persist file found #{inspect(@presets_persist_file)}")
    end
  end

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
    |> Enum.sort_by(&sort_fun/1)
  end

  def delete(cache, key) when cache in @all_cache_keys do
    Cachex.take!(cache, key)
  end

  defp cache_key(%Command{index: index}), do: index
  defp cache_key(%Event{type: type}), do: type
  defp cache_key(%Preset{name: name}), do: name

  defp sort_fun(%Command{index: index}), do: index
  defp sort_fun(%Event{type: type}), do: type
  defp sort_fun(%Preset{updated_at: updated_at}), do: NaiveDateTime.to_erl(updated_at)

  defp maybe_persist_cache(%Preset{}), do: Cachex.dump!(Preset, @presets_persist_file)
  defp maybe_persist_cache(_), do: :noop
end
