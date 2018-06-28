defmodule HelloLeds.LedTest do
  @buttons [5, 16, 20, 22, 26]
  @leds [24, 25, 12, 13, 17, 23, 27, 06, 21]

  @map_a %{
    16 => 17,
    22 => 23,
    26 => 27,
    5 => 6,
    20 => 21
  }

  @map_b %{
    16 => 24,
    22 => 25,
    26 => 12,
    5 => 13,
    20 => nil
  }

  alias ElixirALE.GPIO
  require Logger
  use GenServer

  def start_link([]) do
    # RingLogger.attach()
    # RingLogger.tail()
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    # setup input
    input =
      Map.new(@buttons, fn pin_num ->
        {:ok, pin_pid} = GPIO.start_link(pin_num, :input)
        {pin_num, %{pid: pin_pid}}
      end)

    # setup output and turn all leds on.
    output =
      Map.new(@leds, fn pin_num ->
        Logger.info("LED TEST [  led   ] #{pin_num} => 0")
        {:ok, pin_pid} = GPIO.start_link(pin_num, :output)
        # Process.sleep(300)
        GPIO.write(pin_pid, 0)
        {pin_num, %{pid: pin_pid}}
      end)

    # Process.sleep(500)

    # Turn all leds off.
    # for pin_num <- @leds do
    #   GPIO.write(output[pin_num].pid, 0)
    # end

    GPIO.write(output[17].pid, 1)
    GPIO.write(output[24].pid, 1)

    wait_for_button_input(input, output)

    # Turn all leds off, and release them.
    for pin_num <- @leds do
      GPIO.write(output[pin_num].pid, 0)
      GPIO.release(output[pin_num].pid)
    end

    # Set interupts on every pin
    for pin_num <- @buttons do
      GPIO.set_int(input[pin_num].pid, :both)
      flush_messages()
    end

    # Flush out the mailbox and wait for any
    # button to be pushed
    flush_messages()

    # receive do
    #   _ -> :ok
    # end

    # After one button was pushed, release and restart test.
    for pin_num <- @buttons do
      GPIO.release(input[pin_num].pid)
    end

    init([])
  end

  def flush_messages(timeout \\ 100) do
    receive do
      _ -> flush_messages()
    after
      timeout -> nil
    end
  end

  def wait_for_button_input(
        input,
        output,
        state \\ %{
          16 => 0,
          22 => 0,
          26 => 0,
          5 => 0,
          20 => 0,

          # Big red     # small green
          17 => 1,
          24 => 1,
          # Big yellow  # small blud
          23 => 0,
          25 => 0,
          # big wht     # small wht
          27 => 0,
          12 => 0,
          # big wht     # small wht
          6 => 0,
          13 => 0,
          # bit wht     # nothing
          21 => 0,
          :complete => 0
        }
      )

  # Wait for button 16 to be pushed.
  def wait_for_button_input(input, output, %{17 => 1, 24 => 1} = state) do
    if GPIO.read(input[16].pid) == 1 do
      GPIO.write(output[17].pid, 0)
      GPIO.write(output[24].pid, 0)

      GPIO.write(output[23].pid, 1)
      GPIO.write(output[25].pid, 1)
      wait_for_button_input(input, output, %{state | 16 => 1, 17 => 0, 24 => 0, 23 => 1, 25 => 1})
    else
      wait_for_button_input(input, output, state)
    end
  end

  # Wait for button 22 to be pushed.
  def wait_for_button_input(input, output, %{23 => 1, 25 => 1} = state) do
    if GPIO.read(input[22].pid) == 1 do
      GPIO.write(output[23].pid, 0)
      GPIO.write(output[25].pid, 0)

      GPIO.write(output[27].pid, 1)
      GPIO.write(output[12].pid, 1)
      wait_for_button_input(input, output, %{state | 22 => 1, 23 => 0, 25 => 0, 27 => 1, 12 => 1})
    else
      wait_for_button_input(input, output, state)
    end
  end

  # Wait for button 26 to be pushed.
  def wait_for_button_input(input, output, %{27 => 1, 12 => 1} = state) do
    if GPIO.read(input[26].pid) == 1 do
      GPIO.write(output[27].pid, 0)
      GPIO.write(output[12].pid, 0)

      GPIO.write(output[6].pid, 1)
      GPIO.write(output[13].pid, 1)
      wait_for_button_input(input, output, %{state | 26 => 1, 27 => 0, 12 => 0, 6 => 1, 13 => 1})
    else
      wait_for_button_input(input, output, state)
    end
  end

  # Wait for button 5 to be pushed.
  def wait_for_button_input(input, output, %{6 => 1, 13 => 1} = state) do
    if GPIO.read(input[5].pid) == 1 do
      GPIO.write(output[6].pid, 0)
      GPIO.write(output[13].pid, 0)

      GPIO.write(output[21].pid, 1)
      wait_for_button_input(input, output, %{state | 5 => 1, 6 => 0, 13 => 0, 21 => 1})
    else
      wait_for_button_input(input, output, state)
    end
  end

  # Wait for button 20 to be pushed.
  def wait_for_button_input(input, output, %{21 => 1} = state) do
    if GPIO.read(input[20].pid) == 1 do
      GPIO.write(output[21].pid, 0)
      wait_for_button_input(input, output, %{state | 20 => 1, 21 => 0})
    else
      wait_for_button_input(input, output, state)
    end
  end

  def wait_for_button_input(input, output, %{
        17 => 0,
        24 => 0,
        23 => 0,
        25 => 0,
        27 => 0,
        12 => 0,
        6 => 0,
        13 => 0,
        21 => 0
      }) do
        :ok
      end
end
