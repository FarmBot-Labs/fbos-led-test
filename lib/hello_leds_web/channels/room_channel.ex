defmodule HelloLedsWeb.RoomChannel do
  use Phoenix.Channel

  def join("rooms:lobby", message, socket) do
    IO.puts "HEY!"
    # Process.flag(:trap_exit, true)
    # :timer.send_interval(5000, :ping)
    # send(self, {:after_join, message})
    Elixir.Registry.register(HelloLeds.Registry, :gpio_interrupt, [])

    {:ok, socket}
  end

  # Elixir.Registry.register(HelloLeds.Registry, :gpio_interrupt, [])

  def handle_info({pin, level}, socket) do
    broadcast! socket, "gpio_interupt:change", %{pin: pin, level: level}
    {:noreply, socket}
  end

  def handle_in("led_toggle", %{"pin" => pin, "level" => level}, socket) when is_integer(pin) and is_integer(level) do
    IO.puts "writing: #{pin} => #{level}"
    HelloLeds.LedServer.write(pin, level)
    {:noreply, socket}
  end
end
