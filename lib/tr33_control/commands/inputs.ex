defmodule Tr33Control.Commands.Inputs do
  import EctoEnum

  alias Tr33Control.Commands.{Command, Event, LedStructure}
  alias Tr33Control.Commands.Command.{BallType}
  alias Tr33Control.Commands.Inputs.{Button, Slider, Select, Hidden}

  defenum BallType,
    # square: 0,
    sine: 1,
    comet: 2,
    nyan: 3

  defenum SwipeDirection,
    top_bottom: 0,
    bottom_top: 1,
    left_right: 2,
    right_left: 3

  defenum MappedShape,
    square: 0,
    ball: 1,
    ring: 2

  defenum ColorPalette,
    rainbow: 0,
    forest: 1,
    ocean: 2,
    party: 3,
    heat: 4,
    spring_angel: 5,
    scouty: 6,
    purple_heat: 7,
    # parrot: 8,
    saga: 9,
    sage2: 10

  defenum ColorTemperature,
    none: 0,
    t_1900K: 1,
    t_2600K: 2,
    t_2850K: 3,
    t_3200K: 4,
    t_5200K: 5,
    t_5400K: 6,
    t_6000K: 7,
    t_7000K: 8

  defenum DisplayMode,
    commands: 0,
    stream: 1,
    artnet: 2

  defenum PingPongType,
    linear: 0,
    sine: 1,
    cosine: 2,
    sawtooth: 3

  defenum RenderType,
    ball: 0,
    comet: 1,
    comet_bounce: 2,
    nyan: 3,
    nyan_bounce: 4,
    fill: 5

  defenum SlopeType,
    line: 0,
    fill: 1

  #  Public  ####################################################################################################

  def input_def(struct) do
    input_def(struct, Application.fetch_env!(:tr33_control, :led_structure))
    |> add_index
  end

  defp add_index(inputs) when is_list(inputs) do
    inputs
    |> Enum.with_index()
    |> Enum.map(fn {input, index} -> %{input | index: index} end)
  end

  defp add_index(:disabled), do: :disabled

  #  All  ####################################################################################################

  defp input_def(%Command{type: :disabled}, _), do: []
  defp input_def(%Command{type: :white}, _), do: []
  # defp input_def(%Command{type: :twang}, _), do: []

  defp input_def(%Command{type: :single_color}, _) do
    [
      %Select{name: "StripIndex", options: LedStructure.strip_index_options(), default: strip_index(:all)},
      %Slider{name: "Color", max: 255, default: 226},
      %Slider{name: "Brightness", max: 255, default: 255}
    ]
  end

  defp input_def(%Command{type: :ping_pong}, _) do
    [
      %Select{name: "Render Type", options: RenderType.__enum_map__(), default: 0},
      %Select{name: "StripIndex", options: LedStructure.strip_index_options(), default: strip_index(:all)},
      %Slider{name: "Color", max: 255, default: 65},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "Width", max: 255, default: 20},
      %Select{name: "PingPong Type", options: PingPongType.__enum_map__(), default: 1},
      %Slider{name: "Period [100ms]", max: 255, default: 60},
      %Slider{name: "Offset [100ms]", max: 255, default: 0},
      %Slider{name: "Max height", max: 255, default: 255}
    ]
  end

  defp input_def(%Command{type: :render}, _) do
    [
      %Select{name: "Render Type", options: RenderType.__enum_map__(), default: 0},
      %Select{name: "StripIndex", options: LedStructure.strip_index_options(), default: strip_index(:all)},
      %Slider{name: "Color", max: 255, default: 210},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "Position", max: 255, default: 20},
      %Slider{name: "Width", max: 255, default: 20}
    ]
  end

  defp input_def(%Command{type: :rainbow_sine}, _) do
    [
      %Select{name: "StripIndex", options: LedStructure.strip_index_options(), default: strip_index(:all)},
      %Slider{name: "BPM", max: 255, default: 10},
      %Slider{name: "Wavelength [pixel]", max: 255, default: 100},
      %Slider{name: "Rainbow Width [%]", max: 255, default: 100},
      %Slider{name: "Max Brightness", max: 255, default: 255}
    ]
  end

  defp input_def(%Command{type: :sparkle}, _) do
    [
      %Select{name: "StripIndex", options: LedStructure.strip_index_options(), default: strip_index(:all)},
      %Slider{name: "Color", max: 255, default: 1},
      %Slider{name: "Width", max: 255, default: 15},
      %Slider{name: "Sparkles per second", max: 255, default: 10},
      %Slider{name: "Duration", max: 255, default: 100},
      %Slider{name: "Brightness", max: 100, default: 100}
    ]
  end

  defp input_def(%Command{type: :flicker_sparkle}, _) do
    [
      %Select{name: "StripIndex", options: LedStructure.strip_index_options(), default: strip_index(:all)},
      %Slider{name: "Color", max: 255, default: 255},
      %Slider{name: "Sparkle Width", max: 255, default: 90},
      %Slider{name: "Sparkles per second", max: 255, default: 215},
      %Slider{name: "Duration", max: 255, default: 8},
      %Slider{name: "Flicker Delay", max: 255, default: 7},
      %Slider{name: "Flicker Window", max: 255, default: 119},
      %Slider{name: "Max Number of Flickers", max: 255, default: 80}
    ]
  end

  defp input_def(%Command{type: :rain}, _) do
    [
      %Select{name: "StripIndex", options: LedStructure.strip_index_options(), default: strip_index(:all)},
      %Slider{name: "Color", max: 255, default: 1},
      %Slider{name: "Width", max: 255, default: 15},
      %Slider{name: "Drops per second", max: 255, default: 10},
      %Slider{name: "Rate", max: 255, default: 10}
    ]
  end

  defp input_def(%Command{type: :kaleidoscope}, _) do
    [
      %Select{name: "StripIndex", options: LedStructure.strip_index_options(), default: strip_index(:all)}
    ]
  end

  defp input_def(%Event{type: :update_settings}, _) do
    [
      %Select{name: "Color Palette", options: ColorPalette.__enum_map__(), default: 0},
      %Select{name: "Color Temperature", options: ColorTemperature.__enum_map__(), default: 0},
      %Select{name: "Display Mode", options: DisplayMode.__enum_map__(), default: 0}
    ]
  end

  defp input_def(%Event{type: :pixel}, _) do
    [
      %Select{name: "StripIndex", options: LedStructure.strip_index_options(), default: 0},
      %Slider{name: "LedIndex", max: 100, default: 0},
      %Slider{name: "Color", max: 255, default: 13}
    ]
  end

  defp input_def(%Event{type: :pixel_rgb}, _) do
    [
      %Select{name: "StripIndex", options: LedStructure.strip_index_options(), default: 0},
      %Slider{name: "LedIndex", max: 100, default: 0},
      %Slider{name: "Red", max: 255, default: 13},
      %Slider{name: "Green", max: 255, default: 13},
      %Slider{name: "Blue", max: 255, default: 13}
    ]
  end

  defp input_def(%Command{type: :mapped_slope}, _) do
    [
      %Slider{name: "Color", max: 255, default: 0},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "X1", max: 255, default: 0},
      %Slider{name: "Y1", max: 255, default: 0},
      %Slider{name: "X2", max: 255, default: 255},
      %Slider{name: "Y2", max: 255, default: 255},
      %Slider{name: "Fade Distance", max: 255, default: 5},
      %Select{name: "Type", options: SlopeType.__enum_map__(), default: 0}
    ]
  end

  defp input_def(%Command{type: :mapped_shape}, _) do
    [
      %Slider{name: "Color", max: 255, default: 50},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Select{name: "Shape", options: MappedShape.__enum_map__(), default: 0},
      %Slider{name: "X", max: 255, default: 128},
      %Slider{name: "Y", max: 255, default: 128},
      %Slider{name: "Size", max: 255, default: 50},
      %Slider{name: "Fade Distance", max: 255, default: 50}
    ]
  end

  defp input_def(%Command{type: :mapped_triangle}, _) do
    [
      %Slider{name: "Color", max: 255, default: 0},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "X1", max: 255, default: 20},
      %Slider{name: "Y1", max: 255, default: 20},
      %Slider{name: "X2", max: 255, default: 128},
      %Slider{name: "Y2", max: 255, default: 230},
      %Slider{name: "X3", max: 255, default: 230},
      %Slider{name: "Y3", max: 255, default: 20}
    ]
  end

  defp input_def(%Command{type: :mapped_particles}, _) do
    [
      %Slider{name: "Color", max: 255, default: 50},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Select{name: "Shape", options: MappedShape.__enum_map__(), default: 0},
      %Slider{name: "X", max: 255, default: 128},
      %Slider{name: "Y", max: 255, default: 128},
      %Slider{name: "Size", max: 255, default: 50},
      %Slider{name: "Fade Distance", max: 255, default: 50}
    ]
  end

  defp input_def(%Command{type: :gravity}, _) do
    [
      %Select{name: "StripIndex", options: LedStructure.strip_index_options(), default: strip_index(:all)},
      %Slider{name: "Color", max: 255, default: 13},
      %Slider{name: "Initial Speed", max: 255, default: 0},
      %Slider{name: "New Balls per 10 seconds", max: 100, default: 5},
      %Slider{name: "Width", max: 255, default: 70},
      %Button{name: "Add Ball", event: :gravity}
    ]
  end

  #  Tr33  ###################################################################################################

  # defp input_def(%Command{type: :show_number}, :tr33) do
  #   [
  #     %Select{name: "StripIndex", options: LedStructure.strip_index_options(), default: strip_index(:all_branches)},
  #     %Slider{name: "Number", max: 255, default: 23}
  #   ]
  # end

  ### Dode #########################################################################################

  defp input_def(%Command{type: :random_walk}, :dode) do
    [
      %Slider{name: "Color", max: 255, default: 0},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "Rate", max: 255, default: 5},
      %Slider{name: "Width", max: 255, default: 100},
      %Slider{name: "Ball Count", max: 16, default: 2},
      %Select{name: "Ball Type", options: BallType.__enum_map__(), default: 1}
    ]
  end

  defp input_def(%Command{type: :rotating_sectors}, :dode) do
    [
      %Slider{name: "Color", max: 255, default: 1},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "Period [100ms]", max: 255, default: 100},
      %Slider{name: "Offset", max: 255, default: 0},
      %Slider{name: "Num Sectors", max: 255, default: 3},
      %Slider{name: "Width", max: 255, default: 10}
    ]
  end

  defp input_def(%Command{type: :mapped_swipe}, :dode) do
    [
      %Slider{name: "Color", max: 255, default: 210},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "Position [100ms]", max: 255, default: 40},
      %Slider{name: "Offset [100ms]", max: 255, default: 0},
      %Slider{name: "Width", max: 255, default: 40},
      %Select{name: "Direction", options: SwipeDirection.__enum_map__(), default: 0}
    ]
  end

  defp input_def(%Command{type: :rotating_plane}, :dode) do
    [
      %Slider{name: "Color", max: 255, default: 210},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "Radius", max: 255, default: 128},
      %Slider{name: "Phi", max: 255, default: 40},
      %Slider{name: "Theta", max: 255, default: 120},
      %Slider{name: "Width", max: 255, default: 40}
    ]
  end

  defp input_def(%Command{type: :fireworks}, :dode) do
    [
      %Slider{name: "Color", max: 255, default: 210},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "Rate", max: 255, default: 40},
      %Slider{name: "Width", max: 255, default: 128}
    ]
  end

  defp input_def(_, _), do: :disabled

  defp strip_index(type) do
    case LedStructure.strip_index_options() |> Keyword.fetch(type) do
      {:ok, int} -> int
      _ -> 0
    end
  end
end
