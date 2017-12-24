# ArduinoML implementation in Elixir

This directory is one quick implementation of ArduinoML in Elixir

## Requirements
- An Elixir installation on your system.
- *optional:* Compile the project with ```mix compile```.
- *optional:* Execute the tests with ```mix test```.
- Run it on a file with ```mix run FILE_PATH``` (example: ```mix run samples/switch.exs```).

## Project structure

- The *abstract syntax* is in the [lib/arduino_ml/model](./lib/arduino_ml/model) folder. It is made of structures, so there is no inheritance nor references.
- The *concrete syntax* is in the file [lib/arduino_ml.ex](./lib/arduino_ml.ex).
- The *validation* is in the file [lib/arduino_ml/model_validation/model_validator.ex](./lib/arduino_ml/model_validation/model_validator.ex).
- The *code generation* is in the folder [lib/arduino_ml/code_production](./lib/arduino_ml/code_production).

## Syntax example

This example can be found in [samples/switch.exs](./samples/switch.exs).

```elixir
use ArduinoML

application "Dual-check alarm"

sensor button1: 9
sensor button2: 10
actuator buzzer: 12

state :released, on_entry: :buzzer ~> :low
state :pushed, on_entry: :buzzer ~> :high

transition from: :released, to: :pushed, when: is_high?(:button1) and is_high?(:button2)
transition from: :pushed, to: :released, when: is_low?(:button1)
transition from: :pushed, to: :released, when: is_low?(:button2)

finished! save_into: "output.c"
```

This is transpiled into... that creepy code (& saved into "output.c"):

```c
// generated by ArduinoML #Elixir.

// Bricks <~> Pins.
int BUTTON2 = 10;
int BUTTON1 = 9;
int BUZZER = 12;

// Setup the inputs and outputs.
void setup() {
  pinMode(BUTTON2, INPUT);  pinMode(BUTTON1, INPUT);

  pinMode(BUZZER, OUTPUT);
}

// Static setup code.
int state = LOW;
int prev = HIGH;
long time = 0;
long debounce = 200;

// States declarations.
void state_pushed() {
  digitalWrite(BUZZER, HIGH);

  boolean guard = millis() - time > debounce;

  if (digitalRead(BUTTON2 == LOW) && guard) {
    time = millis();
    state_released();
  } else if (digitalRead(BUTTON1 == LOW) && guard) {
    time = millis();
    state_released();
  } else {
    state_pushed();
  }
}

void state_released() {
  digitalWrite(BUZZER, LOW);

  boolean guard = millis() - time > debounce;

  if (digitalRead(BUTTON1 == HIGH) && digitalRead(BUTTON2 == HIGH) && guard) {
    time = millis();
    state_pushed();
  } else {
    state_released();
  }
}

// This function specifies the first state.
void loop() {
  state_released();
}
```

## TODO List

- Implement more examples.
