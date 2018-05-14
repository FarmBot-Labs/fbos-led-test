defmodule HelloLeds.LedServer do
  @buttons [5, 16, 20, 22, 26]
  @leds [17, 23, 27, 06, 21, 24, 25, 12, 13]
  @registry HelloLeds.Registry
  alias ElixirALE.GPIO
  use GenServer

  def write(led, level), do: GenServer.call(__MODULE__, {:write, led, level})

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do

    buttons = Map.new(@buttons, fn(num) ->
      {:ok, pid} = GPIO.start_link(num, :input)
      GPIO.set_int(pid, :both)
      {num, pid}
    end)

    leds = Map.new(@leds, fn(num) ->
      {:ok, pid} = GPIO.start_link(num, :output)
      :ok = GPIO.write(pid, 0)
      {num, pid}
    end)

    {:ok, %{buttons: buttons, leds: leds}}
  end

  def handle_call({:write, led, level}, _, state) do
    GPIO.write(state.leds[led], level)
    {:reply, :ok, state}
  end

  def handle_info({:gpio_interrupt, pin, level}, state) do
    Registry.dispatch(@registry, :gpio_interrupt, fn entries ->
    for {pid, _} <- entries, do: send( pid, {pin, level}) end)
    {:noreply, state}
  end
end
