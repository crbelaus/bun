defmodule Mix.Tasks.Bun do
  @moduledoc """
  Invokes bun with the given args.

  Usage:

      $ mix bun TASK_OPTIONS PROFILE BUN_ARGS

  Example:

      $ mix bun default assets/js/app.js --outdir=priv/static/assets

  If bun is not installed, it is automatically downloaded.
  Note the arguments given to this task will be appended
  to any configured arguments.

  ## Options

    * `--runtime-config` - load the runtime configuration
      before executing command

  Note flags to control this Mix task must be given before the
  profile:

      $ mix bun --runtime-config default assets/js/app.js

  """

  @shortdoc "Invokes bun with the profile and args"

  use Mix.Task

  @impl true
  def run(args) do
    switches = [runtime_config: :boolean]
    {opts, remaining_args} = OptionParser.parse_head!(args, switches: switches)

    if opts[:runtime_config] do
      Mix.Task.run("app.config")
    else
      Application.ensure_all_started(:bun)
    end

    Mix.Task.reenable("bun")
    install_and_run(remaining_args)
  end

  defp install_and_run([profile | args] = all) do
    case Bun.install_and_run(String.to_atom(profile), args) do
      0 -> :ok
      status -> Mix.raise("`mix bun #{Enum.join(all, " ")}` exited with #{status}")
    end
  end

  defp install_and_run([]) do
    Mix.raise("`mix bun` expects the profile as argument")
  end
end
