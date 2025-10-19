defmodule Bun.Supervisor.Worker do
  @moduledoc false

  @behaviour NimblePool

  defstruct [:port]

  @impl NimblePool
  def init_pool(opts) do
    {:ok, opts}
  end

  @impl NimblePool
  def init_worker(_pool_state) do
    # Workers are stateless - we create a new port for each execution
    {:ok, %__MODULE__{port: nil}, _pool_state = []}
  end

  @impl NimblePool
  def handle_checkout(:checkout, _from, worker, pool_state) do
    {:ok, worker, worker, pool_state}
  end

  @impl NimblePool
  def handle_checkin(_client_state, _from, worker, pool_state) do
    {:ok, worker, pool_state}
  end

  @impl NimblePool
  def terminate_worker(_reason, _worker, pool_state) do
    {:ok, pool_state}
  end

  @doc false
  def execute(_worker, module, args, opts) do
    cd = Keyword.get(opts, :cd, File.cwd!())
    env = Keyword.get(opts, :env, %{})

    # Build the command to execute the JavaScript module
    cmd_args = [module] ++ Enum.map(args, &to_string/1)

    case System.cmd(
           Bun.bin_path(),
           cmd_args,
           cd: cd,
           env: env,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        {:ok, String.trim(output)}

      {output, exit_code} ->
        {:error, {exit_code, String.trim(output)}}
    end
  end
end
