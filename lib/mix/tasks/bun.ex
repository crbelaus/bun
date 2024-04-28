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
  """

  @shortdoc "Invokes bun with the profile and args"
  use Mix.Task

  @requirements ["app.config"]

  @impl true
  def run(args) do
    switches = []
    {_opts, remaining_args} = OptionParser.parse_head!(args, switches: switches)

    Application.ensure_all_started(:bun)

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
