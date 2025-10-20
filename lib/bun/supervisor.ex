defmodule Bun.Supervisor do
  @moduledoc """
  A pooled supervisor for managing bun processes.

  Uses NimblePool to manage a pool of workers that can execute JavaScript
  code via bun. This allows for efficient reuse of bun processes without
  the overhead of spawning new processes for each call.

  ## Usage

      # Start the pool
      {:ok, _pid} = Bun.Supervisor.start_link()

      # Call a JavaScript module
      {:ok, result} = Bun.Supervisor.call("myModule.js", ["arg1", "arg2"])

      # Call with options
      {:ok, result} = Bun.Supervisor.call("myModule.js", [], timeout: 10_000)

      # Call and raise on error
      result = Bun.Supervisor.call!("myModule.js", ["arg1"])

      # Stop the pool
      :ok = Bun.Supervisor.stop()
  """

  alias Bun.Supervisor.Worker

  @pool_name __MODULE__

  @doc """
  Returns a child specification for use in a supervision tree.

  ## Options

    * `:pool_size` - Number of workers in the pool (default: `System.schedulers_online()`)
    * `:name` - Name to register the pool (default: `Bun.Supervisor`)

  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end

  @doc """
  Starts the pool of bun workers.

  ## Options

    * `:pool_size` - Number of workers in the pool (default: `System.schedulers_online()`)
    * `:name` - Name to register the pool (default: `Bun.Supervisor`)

  """
  def start_link(opts \\ []) do
    pool_size = Keyword.get(opts, :pool_size, System.schedulers_online())
    name = Keyword.get(opts, :name, @pool_name)

    pool_opts = [
      worker: {Worker, []},
      pool_size: pool_size,
      name: name
    ]

    NimblePool.start_link(pool_opts)
  end

  @doc """
  Stops the pool.
  """
  def stop(name \\ @pool_name) do
    NimblePool.stop(name)
  end

  @doc """
  Calls a JavaScript module with the given arguments.

  ## Arguments

    * `module` - Path to the JavaScript module to execute
    * `args` - List of arguments to pass to the module (default: `[]`)
    * `opts` - Options for the call

  ## Options

    * `:timeout` - Maximum time to wait for the call in milliseconds (default: `5000`)
    * `:pool` - Name of the pool to use (default: `Bun.Supervisor`)
    * `:cd` - Working directory for the command (default: `File.cwd!()`)
    * `:env` - Environment variables for the command (default: `%{}`)

  ## Returns

    * `{:ok, result}` - The output from the JavaScript module
    * `{:error, reason}` - If the call failed

  """
  def call(module, args \\ [], opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5000)
    pool = Keyword.get(opts, :pool, @pool_name)

    NimblePool.checkout!(
      pool,
      :checkout,
      fn _from, worker ->
        result = Worker.execute(worker, module, args, opts)
        {result, worker}
      end,
      timeout
    )
  end

  @doc """
  Calls a JavaScript module and raises on error.

  See `call/3` for details on arguments and options.

  ## Returns

  The output from the JavaScript module.

  ## Raises

  Raises if the call fails.
  """
  def call!(module, args \\ [], opts \\ []) do
    case call(module, args, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise "Bun call failed: #{inspect(reason)}"
    end
  end
end
