defmodule HelloLeds.LedTest do
  @buttons [5, 16, 20, 22, 26]
  @leds [17, 23, 27, 06, 21, 24, 25, 12, 13]

  @map %{
    16 => 17,
    22 => 23,
    26 => 27,
    5  =>  6,
    20 => 21,
  }

  alias ElixirALE.GPIO
  require Logger
  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    RingLogger.attach()
    RingLogger.tail()

    input = Map.new(@buttons, fn(pin_num) ->
      {:ok, pin_pid} = GPIO.start_link(pin_num, :input)
      GPIO.set_int(pin_pid, :both)
      receive do
        {:gpio_interrupt, ^pin_num, state} ->
          Logger.info "LED TEST [ button ] #{pin_num}: #{state}"
      end
      {pin_num, %{pid: pin_pid}}
    end)

    output = Map.new(@leds, fn(pin_num) ->
      Logger.info "LED TEST [  led   ] #{pin_num} => 1"
      {:ok, pin_pid} = GPIO.start_link(pin_num, :output)
      Process.sleep(300)
      GPIO.write(pin_pid, 1)
      {pin_num, %{pid: pin_pid}}
    end)



    wait_for_button_input(input, output)

    for pin_num <- @buttons do
      GPIO.release(input[pin_num].pid)
    end

    for pin_num <- @leds do
      GPIO.write(output[pin_num].pid, 1)
      GPIO.release(output[pin_num].pid)
    end

    :ignore
  end

  def wait_for_button_input(input, output, state \\ %{
    16 => 0,
    22 => 0,
    26 => 0,
    5  => 0,
    20 => 0,

    17 => 1,
    23 => 1,
    27 => 1,
    6  => 1,
    21 => 1,
  })

  def wait_for_button_input(_input, _output, %{
    17 => 0,
    23 => 0,
    27 => 0,
    6  => 0,
    21 => 0,
  }) do
    :ok
  end

  def wait_for_button_input(input, output, state)  do
    state = Enum.reduce(@buttons, state, fn(button_pin, state) ->
      button_state = GPIO.read(input[button_pin].pid)
      if state[button_pin] == button_state do
        state
      else
        if button_state == 1 do
          led_pin = @map[button_pin]
          led_state = invert(state[led_pin])
          GPIO.write(output[led_pin].pid, led_state)
          Logger.info "LED TEST [ button ] => #{button_state}"
          Logger.info "LED TEST [  led   ] => #{led_state}"
          %{state | button_pin => button_state, led_pin => led_state}
        else
          %{state | button_pin => button_state}
        end
      end
    end)
    wait_for_button_input(input, output, state)
  end

  defp invert(1), do: 0
  defp invert(0), do: 1

end
