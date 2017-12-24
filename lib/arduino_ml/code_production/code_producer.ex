defmodule ArduinoML.CodeProducer do

  alias ArduinoML.Application, as: Application

  @doc """
  Returns a string which is the representation in C code of the application.
  """
  def to_code(app = %Application{sensors: sensors, actuators: actuators, states: states, transitions: transitions}) do
    """
    // generated by ArduinoML #Elixir.

    // Bricks <~> Pins.
    #{sensors ++ actuators |> Enum.map(&brick_declaration/1) |> Enum.join("\n")}
    
    // Setup the inputs and outputs.
    void setup() {
    #{sensors |> Enum.map(fn s -> "  " <> brick_setup(s, :input) end) |> Enum.join("")}

    #{actuators |> Enum.map(fn s -> "  " <> brick_setup(s, :output) end) |> Enum.join("\n")}
    }

    // Static setup code.
    int state = LOW;
    int prev = HIGH;
    long time = 0;
    long debounce = 200;

    // States declarations.
    #{states |> Enum.map(fn state -> state_function(state, transitions) end) |> Enum.join("\n")}
    // This function specifies the first state.
    #{loop_function(app)}
    """
  end

  defp brick_declaration(%{label: label, pin: pin}), do: "int #{brick_label(label)} = #{pin(pin)};"

  defp brick_setup(%{label: label}, stream), do: "pinMode(#{brick_label(label)}, #{brick_label(stream)});"

  defp state_function(%{label: label, actions: actions}, transitions) do
    relevant_transitions = Enum.filter(transitions, fn %{from: from} -> from == label end)

    """
    void #{state_function_name(label)}() {
    #{actions |> Enum.map(&action_declaration/1) |> Enum.map(&("  " <> &1)) |> Enum.join("\n")}
    
      boolean guard = millis() - time > debounce;
    
    #{transitions_declaration(relevant_transitions)} else {
        #{state_function_name(label)}();
      }
    }
    """
  end

  defp action_declaration(%{actuator_label: label, signal: signal}) do
    "digitalWrite(#{brick_label(label)}, #{signal_label(signal)});"
  end

  defp transitions_declaration(transitions) do
    transitions_declaration(transitions, true)
  end

  def transitions_declaration([], _), do: ""
  def transitions_declaration([%{to: to, on: assertions} | others], is_first) do
    partial_condition = assertions |> Enum.map(&condition/1) |> Enum.join(" && ")
    
    "#{condition_keyword(is_first)} (#{partial_condition} && guard) {\n" <>
    "    time = millis();\n" <>
    "    #{state_function_name(to)}();\n" <>
    "  }" <> transitions_declaration(others, false)
  end

  defp condition_keyword(false), do: " else if"
  defp condition_keyword(true), do: "  if"

  defp comparison(:equals), do: "=="
  defp comparison(:lower_than), do: "<"
  defp comparison(:greater_than), do: ">"

  defp condition(%{sensor_label: label, signal: signal, comparison: sign}) do
    "digitalRead(#{brick_label(label)}) #{comparison(sign)} #{signal_label(signal)}"
  end

  defp loop_function(app) do
    "void loop() {\n" <>
    "  #{app |> Application.initial |> state_function_name}();\n" <>
    "}"
  end

  defp state_function_name(label), do: "state_" <> state_label(label)

  defp state_label(label) when is_atom(label), do: label |> Atom.to_string |> String.downcase
  defp state_label(label) when is_binary(label), do: String.downcase(label)

  defp brick_label(label) when is_atom(label), do: label |> Atom.to_string |> String.upcase
  defp brick_label(label) when is_binary(label), do: String.upcase(label)
 
  defp signal_label(label) when is_atom(label), do: label |> Atom.to_string |> String.upcase
  defp signal_label(label) when is_binary(label), do: String.upcase(label)
  defp signal_label(label) when is_integer(label), do: Integer.to_string(label)
  
  defp pin(value) when is_integer(value), do: Integer.to_string(value)
end
