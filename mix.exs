defmodule HelloLeds.MixProject do
  use Mix.Project

  @app :hello_leds

  @target System.get_env("MIX_TARGET") || "rpi3"

  def project do
    [
      app: @app,
      version: "0.3.1",
      elixir: "~> 1.13",
      target: @target,
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      archives: [nerves_bootstrap: "~> 1.10"],
      deps_path: "deps/#{@target}",
      build_path: "_build/#{@target}",
      lockfile: "mix.lock.#{@target}",
      start_permanent: Mix.env() == :prod,
      aliases: [loadconfig: [&bootstrap/1]],
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host],
      deps: deps()
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {HelloLeds.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nerves, "~> 1.7", runtime: false},
      {:shoehorn, "~> 0.9"},
      {:phoenix, "~> 1.6"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_html, "~> 3.2"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:gettext, "~> 0.19"},
      {:poison, "~> 5.0"},
      {:cowboy, "~> 2.9"}
    ] ++ deps(@target)
  end

  # Specify target specific dependencies
  defp deps("host"), do: []

  defp deps(target) do
    [
      {:nerves_runtime, "~> 0.11"},
      # {:nerves_init_gadget, "~> 0.3"},
      {:elixir_ale, "~> 1.2"}
    ] ++ system(target)
  end

  defp system("rpi"), do: [{:nerves_system_rpi, "~> 1.8", runtime: false}]
  defp system("rpi0"), do: [{:nerves_system_rpi0, "~> 1.8", runtime: false}]
  defp system("rpi2"), do: [{:nerves_system_rpi2, "~> 1.8", runtime: false}]
  defp system("rpi3"), do: [{:nerves_system_rpi3, "~> 1.8", runtime: false}]
  defp system("rpi3a"), do: [{:nerves_system_rpi3a, "~> 1.8", runtime: false}]
  defp system("rpi4"), do: [{:nerves_system_rpi4, "~> 1.8", runtime: false}]
  defp system("bbb"), do: [{:nerves_system_bbb, "~> 1.8", runtime: false}]
  defp system("ev3"), do: [{:nerves_system_ev3, "~> 1.8", runtime: false}]
  defp system("qemu_arm"), do: [{:nerves_system_qemu_arm, "~> 1.8", runtime: false}]
  defp system("x86_64"), do: [{:nerves_system_x86_64, "~> 1.8", runtime: false}]
  defp system(target), do: Mix.raise("Unknown MIX_TARGET: #{target}")
end
