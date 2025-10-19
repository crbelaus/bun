defmodule BunTest do
  use ExUnit.Case, async: true

  @version Bun.latest_version()
  @fixtures_path Path.expand("fixtures", __DIR__)

  test "run on default" do
    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Bun.run(:default, ["--version"]) == 0
           end) =~ @version
  end

  test "run on profile" do
    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Bun.run(:another, []) == 0
           end) =~ @version
  end

  test "updates on install" do
    Application.put_env(:bun, :version, "1.1.0")

    Mix.Task.rerun("bun.install", ["--if-missing"])

    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Bun.run(:default, ["--version"]) == 0
           end) =~ "1.1.0"

    Application.delete_env(:bun, :version)

    Mix.Task.rerun("bun.install", ["--if-missing"])

    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Bun.run(:default, ["--version"]) == 0
           end) =~ @version
  after
    Application.delete_env(:bun, :version)
  end

  describe "pooled execution" do
    setup do
      pool_name = :"test_pool_#{System.unique_integer()}"
      {:ok, _pid} = Bun.start_link(name: pool_name)

      on_exit(fn ->
        try do
          Bun.stop(pool_name)
        catch
          :exit, _ -> :ok
        end
      end)

      {:ok, pool: pool_name}
    end

    test "Bun.call/3 executes JavaScript modules", %{pool: pool} do
      hello_path = Path.join(@fixtures_path, "hello.js")
      assert {:ok, result} = Bun.call(hello_path, [], pool: pool)
      assert result == "Hello from bun!"
    end

    test "Bun.call/3 with arguments", %{pool: pool} do
      add_path = Path.join(@fixtures_path, "add.js")
      assert {:ok, result} = Bun.call(add_path, ["10", "20"], pool: pool)
      assert result == "30"
    end

    test "Bun.call!/3 returns result directly", %{pool: pool} do
      hello_path = Path.join(@fixtures_path, "hello.js")
      assert result = Bun.call!(hello_path, ["world"], pool: pool)
      assert result == "world"
    end

    test "Bun.call!/3 raises on error", %{pool: pool} do
      error_path = Path.join(@fixtures_path, "error.js")

      assert_raise RuntimeError, ~r/Bun call failed/, fn ->
        Bun.call!(error_path, [], pool: pool)
      end
    end
  end
end
