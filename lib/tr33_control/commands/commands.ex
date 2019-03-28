defmodule Tr33Control.Commands do
  import Ecto.Query, only: [from: 2]
  alias Ecto.Changeset
  alias Tr33Control.Repo
  alias Tr33Control.Commands.{Command, UART, Event, Cache, Preset}

  @max_index Application.fetch_env!(:tr33_control, :command_max_index)

  @topic "inspect(__MODULE__)"

  def subscribe do
    Phoenix.PubSub.subscribe(Tr33Control.PubSub, @topic)
  end

  def update_subscribers() do
    Phoenix.PubSub.broadcast!(Tr33Control.PubSub, @topic, :update)
  end

  def init() do
    Cache.init()

    case latest_preset() do
      %Preset{name: name} -> load_preset(name)
      nil -> :noop
    end
  end

  def new_command!(params) do
    new_command(params)
    |> raise_on_error()
  end

  def new_command(params) when is_map(params) do
    %Command{}
    |> Command.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
  end

  def new_command(binary) when is_binary(binary) do
    binary
    |> Command.from_binary()
  end

  def add_command() do
    next_index =
      case list_commands() |> Enum.reverse() do
        [%Command{index: index} | _] -> index + 1
        [] -> 0
      end

    Command.defaults(next_index)
    |> send()
  end

  def list_commands() do
    Cache.all_commands()
  end

  def get_command(index) do
    Cache.get_command(index)
  end

  def delete_last_command() do
    case Cache.all_commands() |> Enum.reverse() do
      [%Command{index: index} | _] ->
        Cache.delete_command(index)
        index

      [] ->
        0
    end
  end

  def new_event(params) do
    %Event{}
    |> Event.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
  end

  def new_event!(params) do
    new_event(params)
    |> raise_on_error()
  end

  def get_event(type) do
    Cache.get_event(type)
  end

  def list_events() do
    Cache.all_events()
  end

  def send(%Command{index: index} = command) when index <= @max_index do
    command
    |> Cache.insert()
    |> UART.send()
  end

  def send(%Command{} = command), do: command

  def send(%Event{} = event) do
    event
    |> maybe_insert()
    |> UART.send()
  end

  def change_preset(preset, attrs \\ %{}) do
    Preset.changeset(preset, attrs)
  end

  def create_preset(attrs) do
    commands = list_commands()
    events = list_events()

    attrs
    |> get_or_new_preset()
    |> Changeset.put_change(:commands, commands)
    |> Changeset.put_change(:events, events)
    |> Repo.insert_or_update()
  end

  def list_presets() do
    query = from(p in Preset, order_by: [asc: p.name])

    Repo.all(query)
  end

  def load_preset(%Preset{commands: commands, events: events, name: name} = preset) do
    Cache.clear()

    (commands ++ events)
    |> Enum.map(&Cache.insert/1)

    UART.resync()

    preset
  end

  def load_preset(name) when is_binary(name) and not is_nil(name) do
    Repo.get_by!(Preset, name: name)
    |> load_preset()
  end

  def latest_preset() do
    query = from(p in Preset, order_by: [desc: p.updated_at], limit: 1)
    Repo.one(query)
  end

  def command_types(), do: Command.types()
  def event_types(), do: Event.types()

  def data_inputs(%Event{} = event), do: Event.data_inputs(event)
  def data_inputs(%Command{} = command), do: Command.data_inputs(command)

  defp raise_on_error({:ok, result}), do: result

  defp raise_on_error(error), do: raise(RuntimeError, message: "Could not create command: #{inspect(error)}")

  defp update_current_preset({:ok, %Preset{name: name}} = result) do
    Application.put_env(:tr33_control, :current_preset, name)
    result
  end

  defp update_current_preset(result), do: result

  defp maybe_insert(%Event{} = event) do
    if Event.persist?(event), do: Cache.insert(event)
    event
  end

  defp get_or_new_preset(%{"name" => name} = attr) do
    case Repo.get_by(Preset, name: name) do
      nil -> change_preset(%Preset{}, attr)
      preset = %Preset{} -> change_preset(preset)
    end
  end

  defp notify_subscribers({:ok, result}, event) do
    Phoenix.PubSub.broadcast(Demo.PubSub, @topic, {__MODULE__, event, result})
    Phoenix.PubSub.broadcast(Demo.PubSub, @topic <> "#{result.id}", {__MODULE__, event, result})
    {:ok, result}
  end

  defp notify_subscribers({:error, reason}, _event), do: {:error, reason}
end
