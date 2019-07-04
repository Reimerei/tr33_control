defmodule Tr33Control.Commands do
  alias Ecto.Changeset
  alias Tr33Control.Commands.{Command, UART, Event, Cache, Preset}

  @max_index Application.fetch_env!(:tr33_control, :command_max_index)

  @topic "#{inspect(__MODULE__)}"

  def subscribe do
    Phoenix.PubSub.subscribe(Tr33Control.PubSub, @topic)
  end

  def notify_subscribers(message) do
    Phoenix.PubSub.broadcast!(Tr33Control.PubSub, @topic, message)
  end

  def init() do
    Cache.init_all()

    Cache.all(Preset)
    |> List.last()
    |> load_preset()
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

  def append_empty_command() do
    next_index =
      case list_commands() |> List.last() do
        %Command{index: index} -> index + 1
        nil -> 0
      end

    Command.defaults(next_index)
    |> send()
  end

  def list_commands() do
    Cache.all(Command)
  end

  def get_command(index) do
    Cache.get(Command, index)
  end

  def delete_last_command() do
    case list_commands() |> List.last() do
      %Command{index: index} ->
        Cache.delete(Command, index)
        index

      nil ->
        0
    end
  end

  def swap_commands(%Command{index: index} = command, new_index) when new_index >= 0 and new_index <= @max_index do
    swapped_command = get_command(new_index)

    %Command{swapped_command | index: index}
    |> send()

    %Command{command | index: new_index}
    |> send()
  end

  def swap_commands(%Command{} = command, _), do: command

  def clone_command(%Command{} = command, new_index) when new_index >= 0 and new_index <= @max_index do
    %Command{command | index: new_index}
    |> send()
  end

  def clone_command(%Command{} = command, _), do: command

  def new_event(params) when is_map(params) do
    %Event{}
    |> Event.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
  end

  def new_event(binary) when is_binary(binary) do
    binary
    |> Event.from_binary()
  end

  def new_event!(params) do
    new_event(params)
    |> raise_on_error()
  end

  def get_event(type) do
    Cache.get(Event, type)
  end

  def list_events() do
    Cache.all(Event)
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
    |> Changeset.put_change(:updated_at, NaiveDateTime.utc_now())
    |> Ecto.Changeset.apply_action(:insert)
    |> maybe_insert()
  end

  def list_presets() do
    Cache.all(Preset)
  end

  def load_preset(%Preset{commands: commands, events: events} = preset) do
    Cache.clear(Command)
    Cache.clear(Event)

    (commands ++ events)
    |> Enum.map(&Cache.insert/1)

    UART.resync()
    preset
  end

  def load_preset(name) when is_binary(name) do
    Cache.get(Preset, name)
    |> load_preset()
  end

  def load_preset(nil), do: :noop

  def command_types(), do: Command.types()
  def event_types(), do: Event.types()

  def inputs(%Event{} = event), do: Event.inputs(event)
  def inputs(%Command{} = command), do: Command.inputs(command)

  defp raise_on_error({:ok, result}), do: result

  defp raise_on_error(error), do: raise(RuntimeError, message: "Could not create: #{inspect(error)}")

  defp maybe_insert(%Event{} = event) do
    if Event.persist?(event), do: Cache.insert(event)
    event
  end

  defp maybe_insert({:error, _} = response), do: response

  defp maybe_insert({:ok, struct} = response) do
    Cache.insert(struct)
    response
  end

  defp get_or_new_preset(%{"name" => name} = attr) do
    case Cache.get(Preset, name) do
      nil -> change_preset(%Preset{}, attr)
      preset = %Preset{} -> change_preset(preset)
    end
  end
end
