defmodule Tr33Control.Commands.Inputs do
  import EctoEnum

  alias Tr33Control.Commands.{Command, Event}
  alias Tr33Control.Commands.Command.{StripIndex, BallType}
  alias Tr33Control.Commands.Inputs.{Button, Slider, Select, Hidden}

  @trunk_count 8
  @branch_count 12
  @strip_index_values [
                        all: @trunk_count + @branch_count + 2,
                        all_trunks: @trunk_count + @branch_count,
                        all_branches: @trunk_count + @branch_count + 1
                      ] ++
                        Enum.map(0..(@trunk_count - 1), &{:"trunk_#{&1}", &1}) ++
                        Enum.map(0..(@branch_count - 1), &{:"branch_#{&1}", &1 + @trunk_count})

  defenum StripIndex, @strip_index_values

  defenum BallType,
    # square: 0,
    sine: 1,
    comet: 2,
    nyan: 3

  # fill_top: 4,
  # fill_bottom: 5

  defenum SwipeDirection,
    top_bottom: 0,
    bottom_top: 1,
    left_right: 2,
    right_left: 3

  defenum MappedShape,
    square: 0,
    hollow_square: 1,
    circle: 2

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
    stream: 1

  defenum PingPongType,
    linear: 0,
    sine: 1,
    cosine: 2,
    sawtooth: 3

  defenum FillType,
    ball: 0,
    top: 1,
    bottom: 2

  #  Public  ####################################################################################################

  def input_def(struct), do: input_def(struct, Application.fetch_env!(:tr33_control, :led_structure))

  #  All  ####################################################################################################

  defp input_def(%Command{type: :disabled}, _), do: []
  defp input_def(%Command{type: :white}, _), do: []

  defp input_def(%Event{type: :update_settings}, _) do
    [
      %Select{name: "Color Palette", options: ColorPalette.__enum_map__(), default: 0},
      %Select{name: "Color Temperature", options: ColorTemperature.__enum_map__(), default: 0},
      %Select{name: "Display Mode", options: DisplayMode.__enum_map__(), default: 0}
    ]
  end

  #  Tr33  ###################################################################################################

  defp input_def(%Command{type: :single_color}, :tr33) do
    [
      %Select{name: "StripIndex", options: StripIndex.__enum_map__(), default: strip_index(:all)},
      %Slider{name: "Color", max: 255, default: 226},
      %Slider{name: "Brightness", max: 255, default: 255}
    ]
  end

  defp input_def(%Command{type: :rainbow_sine}, :tr33) do
    [
      %Select{name: "StripIndex", options: StripIndex.__enum_map__(), default: strip_index(:all)},
      %Slider{name: "BPM", max: 255, default: 10},
      %Slider{name: "Wavelength [pixel]", max: 255, default: 100},
      %Slider{name: "Rainbow Width [%]", max: 255, default: 100},
      %Slider{name: "Max Brightness", max: 255, default: 255}
    ]
  end

  defp input_def(%Command{type: :ping_pong}, :tr33) do
    [
      %Select{name: "StripIndex", options: StripIndex.__enum_map__(), default: strip_index(:all_trunks)},
      %Select{name: "Ball Type", options: BallType.__enum_map__(), default: 1},
      %Slider{name: "Color", max: 255, default: 65},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "Width", max: 255, default: 90},
      %Slider{name: "Period [100ms]", max: 255, default: 60},
      %Slider{name: "Offset [100ms]", max: 255, default: 0}
    ]
  end

  defp input_def(%Command{type: :gravity}, :tr33) do
    [
      %Select{name: "StripIndex", options: StripIndex.__enum_map__(), default: strip_index(:all)},
      %Slider{name: "Color", max: 255, default: 13},
      %Slider{name: "Initial Speed", max: 255, default: 0},
      %Slider{name: "New Balls per 10 seconds", max: 100, default: 5},
      %Slider{name: "Width", max: 255, default: 70},
      %Button{name: "Add Ball", event: :gravity}
    ]
  end

  defp input_def(%Command{type: :sparkle}, :tr33) do
    [
      %Select{name: "StripIndex", options: StripIndex.__enum_map__(), default: strip_index(:all_branches)},
      %Slider{name: "Color", max: 255, default: 1},
      %Slider{name: "Width", max: 255, default: 15},
      %Slider{name: "Sparkles per second", max: 255, default: 10}
    ]
  end

  defp input_def(%Command{type: :rain}, :tr33) do
    [
      %Select{name: "StripIndex", options: StripIndex.__enum_map__(), default: strip_index(:all_branches)},
      %Slider{name: "Color", max: 255, default: 1},
      %Slider{name: "Width", max: 255, default: 15},
      %Slider{name: "Drops per second", max: 255, default: 10},
      %Slider{name: "Rate", max: 255, default: 10}
    ]
  end

  # defp input_def(%Command{type: :show_number}, :tr33) do
  #   [
  #     %Select{name: "StripIndex", options: StripIndex.__enum_map__(), default: strip_index(:all_branches)},
  #     %Slider{name: "Number", max: 255, default: 23}
  #   ]
  # end

  defp input_def(%Command{type: :mapped_swipe}, :tr33) do
    [
      %Select{name: "Swipe Direction", options: SwipeDirection.__enum_map__(), default: 0},
      %Slider{name: "Color", max: 255, default: 100},
      %Slider{name: "Rate", max: 255, default: 100}
    ]
  end

  defp input_def(%Command{type: :mapped_shape}, :tr33) do
    [
      %Select{name: "Shape", options: MappedShape.__enum_map__(), default: 0},
      %Slider{name: "Color", max: 255, default: 50},
      %Slider{name: "X", max: 255, default: 100},
      %Slider{name: "Y", max: 255, default: 100},
      %Slider{name: "Size", max: 255, default: 50}
    ]
  end

  defp input_def(%Event{type: :pixel}, :tr33) do
    [
      %Select{name: "StripIndex", options: StripIndex.__enum_map__(), default: 0},
      %Slider{name: "LedIndex", max: 100, default: 0},
      %Slider{name: "Color", max: 255, default: 13}
    ]
  end

  defp input_def(%Event{type: :pixel_rgb}, :tr33) do
    [
      %Select{name: "StripIndex", options: StripIndex.__enum_map__(), default: 0},
      %Slider{name: "LedIndex", max: 100, default: 0},
      %Slider{name: "Red", max: 255, default: 13},
      %Slider{name: "Green", max: 255, default: 13},
      %Slider{name: "Blue", max: 255, default: 13}
    ]
  end

  ### Dode #########################################################################################

  defp input_def(%Command{type: :single_color}, :dode) do
    [
      %Slider{name: "Strip Index", max: 30, default: 30},
      %Slider{name: "Color", max: 255, default: 226},
      %Slider{name: "Brightness", max: 255, default: 255}
    ]
  end

  defp input_def(%Command{type: :kaleidoscope}, :dode) do
    [
      %Slider{name: "Color", max: 255, default: 226},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "Period [100ms]", max: 255, default: 60},
      %Slider{name: "Offset [100ms]", max: 255, default: 0}
    ]
  end

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

  defp input_def(%Command{type: :sparkle}, :dode) do
    [
      %Hidden{default: 30},
      %Slider{name: "Color", max: 255, default: 1},
      %Slider{name: "Width", max: 255, default: 15},
      %Slider{name: "Sparkles per second", max: 255, default: 10}
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

  defp input_def(%Command{type: :ping_pong}, :dode) do
    [
      %Select{name: "Type", options: PingPongType.__enum_map__(), default: 1},
      %Slider{name: "Color", max: 255, default: 65},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "Width", max: 255, default: 20},
      %Slider{name: "Period [100ms]", max: 255, default: 60},
      %Slider{name: "Offset [100ms]", max: 255, default: 0}
    ]
  end

  defp input_def(%Command{type: :fill}, :dode) do
    [
      %Select{name: "Type", options: FillType.__enum_map__(), default: 0},
      %Slider{name: "Color", max: 255, default: 210},
      %Slider{name: "Brightness", max: 255, default: 255},
      %Slider{name: "Position", max: 255, default: 20},
      %Slider{name: "Width", max: 255, default: 20}
    ]
  end

  defp input_def(_, _), do: :disabled

  defp strip_index(type) do
    case StripIndex.dump(type) do
      {:ok, int} -> int
    end
  end
end
