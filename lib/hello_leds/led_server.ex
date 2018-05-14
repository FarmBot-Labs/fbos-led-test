defmodule HelloLeds.LedServer do
  @buttons [5, 16, 20, 22, 26]
  @leds [17, 23, 27, 06, 21, 24, 25, 12, 13]
  @registry HelloLeds.Registry
  alias ElixirALE.GPIO
  use GenServer

  def write(led, level), do: GenServer.cast(__MODULE__, {:write, led, level})

  def dance do
    GenServer.cast(__MODULE__, :dance)
  end

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

  def handle_cast({:write, led, level}, state) do
    GPIO.write(state.leds[led], level)
    dispatch(led, level)
    {:reply, :ok, state}
  end

  def handle_cast(:dance, state) do
    for {led, pid} <- state.leds do
      GPIO.write(pid, 1)
      dispatch(led, 1)
      Process.sleep(100)
    end

    Process.sleep(500)

    for {led, pid} <- state.leds do
      GPIO.write(pid, 0)
      dispatch(led, 0)
      Process.sleep(100)
    end
  end

  def handle_info({:gpio_interrupt, pin, :rising}, state) do
    dispatch(pin, 1)
    {:noreply, state}
  end

  def handle_info({:gpio_interrupt, pin, :falling}, state) do
    dispatch(pin, 0)
    {:noreply, state}
  end

  defp dispatch(pin, level) do
    Registry.dispatch(@registry, :gpio_interrupt, fn entries ->
    for {pid, _} <- entries, do: send( pid, {pin, level}) end)
  end
end
