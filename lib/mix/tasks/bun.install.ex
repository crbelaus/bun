defmodule Mix.Tasks.Bun.Install do
  @moduledoc """
  Installs bun under `_build`.

  ```bash
  $ mix bun.install
  $ mix bun.install --if-missing
  ```

  By default, it installs #{Bun.latest_version()} but you
  can configure it in your config files, such as:

      config :bun, :version, "#{Bun.latest_version()}"

  ## Options

      * `--if-missing` - install only if the given version
        does not exist
  """

  @shortdoc "Installs bun under _build"
  use Mix.Task

  @requirements ["app.config"]

  @impl true
  def run(args) do
    valid_options = [runtime_config: :boolean, if_missing: :boolean]

    case OptionParser.parse_head!(args, strict: valid_options) do
      {opts, []} ->
        if opts[:if_missing] && latest_version?() do
          :ok
        else
          Bun.install()
        end

      {_, _} ->
        Mix.raise("""
        Invalid arguments to bun.install, expected one of:

            mix bun.install
            mix bun.install --if-missing
        """)
    end
  end

  defp latest_version?() do
    version = Bun.configured_version()
    match?({:ok, ^version}, Bun.bin_version())
  end
end
