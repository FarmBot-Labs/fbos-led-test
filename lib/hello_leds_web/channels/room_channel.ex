defmodule HelloLedsWeb.RoomChannel do
  use Phoenix.Channel

  def join("rooms:lobby", _message, socket) do
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

  def handle_in("dance", _, socket) do
    HelloLeds.LedServer.dance()
    {:noreply, socket}
  end
end
