defmodule Bun do
  # https://github.com/oven-sh/bun/releases
  @latest_version "1.1.42"
  @min_windows_version "1.1.0"

  @moduledoc """
  Bun is an installer and runner for [bun](https://bun.sh).

  ## Profiles

  You can define multiple bun profiles. By default, there is a
  profile called `:default` which you can configure its args, current
  directory and environment:

      config :bun,
        version: "#{@latest_version}",
        default: [
          args: ~w(build js/app.js  --outdir=../priv/static/assets),
          cd: Path.expand("../assets", __DIR__),
          env: %{}
        ]

  ## Bun configuration

  There are two global configurations for the bun application:

    * `:version` - the expected bun version

    * `:cacerts_path` - the directory to find certificates for
      https connections

    * `:path` - the path to find the bun executable at. By
      default, it is automatically downloaded and placed inside
      the `_build` directory of your current app

  Overriding the `:path` is not recommended, as we will automatically
  download and manage `bun` for you. But in case you can't download
  it (for example, the npm registry is behind a proxy), you may want to
  set the `:path` to a configurable system location.

  Once you find the location of the executable, you can store it in a
  `MIX_BUN_PATH` environment variable, which you can then read in
  your configuration file:

      config :bun, path: System.get_env("MIX_BUN_PATH")

  """

  use Application
  require Logger

  @doc false
  def start(_, _) do
    unless Application.get_env(:bun, :version) do
      Logger.warning("""
      bun version is not configured. Please set it in your config files:

          config :bun, :version, "#{latest_version()}"
      """)
    end

    configured_version = configured_version()

    case bin_version() do
      {:ok, ^configured_version} ->
        :ok

      {:ok, version} ->
        Logger.warning("""
        Outdated bun version. Expected #{configured_version}, got #{version}. \
        Please run `mix bun.install` or update the version in your config files.\
        """)

      :error ->
        :ok
    end

    Supervisor.start_link([], strategy: :one_for_one)
  end

  @doc false
  # Latest known version at the time of publishing.
  def latest_version, do: @latest_version

  @doc """
  Returns the configured bun version.
  """
  def configured_version do
    version = Application.get_env(:bun, :version, latest_version())

    case :os.type() do
      {:win32, _} ->
        if Version.compare(version, @min_windows_version) in [:eq, :gt] do
          version
        else
          raise "bun on windows is available starting from #{@min_windows_version}"
        end

      _ ->
        version
    end
  end

  @doc """
  Returns the configuration for the given profile.

  Returns nil if the profile does not exist.
  """
  def config_for!(profile) when is_atom(profile) do
    Application.get_env(:bun, profile) ||
      raise ArgumentError, """
      unknown bun profile. Make sure the profile is defined in your config/config.exs file, such as:

          config :bun,
            #{profile}: [
              args: ~w(js/app.js --outdir=../priv/static/assets),
              cd: Path.expand("../assets", __DIR__),
              env: %{"ENV_VAR" => "value"}
            ]
      """
  end

  @doc """
  Returns the path to the executable.

  The executable may not be available if it was not yet installed.
  """
  def bin_path do
    name =
      case :os.type() do
        {:win32, _} -> "bun.exe"
        _ -> "bun"
      end

    Application.get_env(:bun, :path) ||
      if Code.ensure_loaded?(Mix.Project) do
        Path.join(Path.dirname(Mix.Project.build_path()), name)
      else
        Path.expand("_build/#{name}")
      end
  end

  @doc """
  Returns the version of the bun executable.

  Returns `{:ok, version_string}` on success or `:error` when the executable
  is not available.
  """
  def bin_version do
    path = bin_path()

    with true <- File.exists?(path),
         {result, 0} <- System.cmd(path, ["--version"]) do
      {:ok, String.trim(result)}
    else
      _ -> :error
    end
  end

  @doc """
  Runs the given command with `args`.

  The given args will be appended to the configured args.
  The task output will be streamed directly to stdio. It
  returns the status of the underlying call.
  """
  def run(profile, extra_args) when is_atom(profile) and is_list(extra_args) do
    config = config_for!(profile)
    args = (config[:args] || []) ++ extra_args

    {_, exit_status} =
      run_bun_command(args,
        cd: config[:cd] || File.cwd!(),
        env: config[:env] || %{},
        into: IO.stream(:stdio, :line),
        stderr_to_stdout: true
      )

    exit_status
  end

  defp run_bun_command([], _opts) do
    raise "no arguments passed to bun"
  end

  # `bun build` will keep running as a zombie process even after closing the parent Elixir
  # process. The wrapper script monitors stdin to ensure that the bun process is closed.
  defp run_bun_command(["build" | _] = args, opts) do
    wrapper_path = Path.join(:code.priv_dir(:bun), "wrapper.js")

    System.cmd(bin_path(), [wrapper_path, bin_path()] ++ args, opts)
  end

  # Other commands such as `bun run` don't leave zombie processes and can be run directly.
  defp run_bun_command(args, opts) do
    System.cmd(bin_path(), args, opts)
  end

  @doc """
  Installs, if not available, and then runs `bun`.

  Returns the same as `run/2`.
  """
  def install_and_run(profile, args) do
    unless File.exists?(bin_path()) do
      install()
    end

    run(profile, args)
  end

  def install do
    version = configured_version()
    tmp_opts = if System.get_env("MIX_XDG"), do: %{os: :linux}, else: %{}

    tmp_dir =
      freshdir_p(:filename.basedir(:user_cache, "phx-bun", tmp_opts)) ||
        freshdir_p(Path.join(System.tmp_dir!(), "phx-bun")) ||
        raise "could not install bun. Set MIX_XGD=1 and then set XDG_CACHE_HOME to the path you want to use as cache"

    url = "https://github.com/oven-sh/bun/releases/download/bun-v#{version}/bun-#{target()}.zip"

    zip = fetch_body!(url)

    download_path =
      case :zip.unzip(zip, cwd: to_charlist(tmp_dir)) do
        {:ok, [download_path]} -> download_path
        # OTP 27.1 and newer versions return both the unzipped folder and file
        {:ok, [_download_folder, download_path]} -> download_path
        other -> raise "couldn't unpack archive: #{inspect(other)}"
      end

    bin_path = bin_path()
    File.mkdir_p!(Path.dirname(bin_path))

    File.cp!(download_path, bin_path)
    File.chmod(bin_path, 0o755)
  end

  defp freshdir_p(path) do
    with {:ok, _} <- File.rm_rf(path),
         :ok <- File.mkdir_p(path) do
      path
    else
      _ -> nil
    end
  end

  defp target do
    case :os.type() do
      # Assuming it's an x86 CPU
      {:win32, _} ->
        "windows-x64"

      {:unix, osname} ->
        arch_str = :erlang.system_info(:system_architecture)
        [arch | _] = arch_str |> List.to_string() |> String.split("-")

        case arch do
          "amd64" -> "#{osname}-x64"
          "x86_64" -> "#{osname}-x64"
          "i686" -> "#{osname}-ia32"
          "i386" -> "#{osname}-ia32"
          "aarch64" -> "#{osname}-aarch64"
          _ -> raise "bun is not available for architecture: #{arch_str}"
        end
    end
  end

  defp fetch_body!(url) do
    scheme = URI.parse(url).scheme
    url = String.to_charlist(url)
    Logger.debug("Downloading bun from #{url}")

    Mix.ensure_application!(:inets)
    Mix.ensure_application!(:ssl)

    if proxy = proxy_for_scheme(scheme) do
      %{host: host, port: port} = URI.parse(proxy)
      Logger.debug("Using #{String.upcase(scheme)}_PROXY: #{proxy}")
      set_option = if "https" == scheme, do: :https_proxy, else: :proxy
      :httpc.set_options([{set_option, {{String.to_charlist(host), port}, []}}])
    end

    # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
    cacertfile = cacertfile() |> String.to_charlist()

    http_options =
      [
        ssl: [
          verify: :verify_peer,
          cacertfile: cacertfile,
          depth: 2,
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      ]
      |> maybe_add_proxy_auth(scheme)

    options = [body_format: :binary]

    case :httpc.request(:get, {url, []}, http_options, options) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        body

      other ->
        raise """
        couldn't fetch #{url}: #{inspect(other)}

        You may also install the "bun" executable manually, \
        see the docs: https://hexdocs.pm/bun
        """
    end
  end

  defp proxy_for_scheme("http") do
    System.get_env("HTTP_PROXY") || System.get_env("http_proxy")
  end

  defp proxy_for_scheme("https") do
    System.get_env("HTTPS_PROXY") || System.get_env("https_proxy")
  end

  defp maybe_add_proxy_auth(http_options, scheme) do
    case proxy_auth(scheme) do
      nil -> http_options
      auth -> [{:proxy_auth, auth} | http_options]
    end
  end

  defp proxy_auth(scheme) do
    with proxy when is_binary(proxy) <- proxy_for_scheme(scheme),
         %{userinfo: userinfo} when is_binary(userinfo) <- URI.parse(proxy),
         [username, password] <- String.split(userinfo, ":") do
      {String.to_charlist(username), String.to_charlist(password)}
    else
      _ -> nil
    end
  end

  defp cacertfile() do
    Application.get_env(:bun, :cacerts_path) || CAStore.file_path()
  end
end
