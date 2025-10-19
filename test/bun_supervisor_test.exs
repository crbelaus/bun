defmodule Bun.SupervisorTest do
  use ExUnit.Case, async: true

  @fixtures_path Path.expand("fixtures", __DIR__)

  setup do
    # Start a pool for each test with a unique name
    pool_name = :"test_pool_#{System.unique_integer()}"
    {:ok, _pid} = Bun.Supervisor.start_link(name: pool_name)

    on_exit(fn ->
      try do
        Bun.Supervisor.stop(pool_name)
      catch
        :exit, _ -> :ok
      end
    end)

    {:ok, pool: pool_name}
  end

  describe "start_link/1" do
    test "starts a pool with default options" do
      {:ok, pid} = Bun.Supervisor.start_link(name: :test_start_default)
      assert Process.alive?(pid)
      Bun.Supervisor.stop(:test_start_default)
    end

    test "starts a pool with custom pool size" do
      {:ok, pid} = Bun.Supervisor.start_link(pool_size: 2, name: :test_start_custom)
      assert Process.alive?(pid)
      Bun.Supervisor.stop(:test_start_custom)
    end
  end

  describe "call/3" do
    test "executes a simple JavaScript module", %{pool: pool} do
      hello_path = Path.join(@fixtures_path, "hello.js")
      assert {:ok, result} = Bun.Supervisor.call(hello_path, [], pool: pool)
      assert result == "Hello from bun!"
    end

    test "executes a module with arguments", %{pool: pool} do
      hello_path = Path.join(@fixtures_path, "hello.js")
      assert {:ok, result} = Bun.Supervisor.call(hello_path, ["test", "args"], pool: pool)
      assert result == "test args"
    end

    test "executes a module that performs computation", %{pool: pool} do
      add_path = Path.join(@fixtures_path, "add.js")
      assert {:ok, result} = Bun.Supervisor.call(add_path, ["5", "3"], pool: pool)
      assert result == "8"
    end

    test "returns error tuple for failing module", %{pool: pool} do
      error_path = Path.join(@fixtures_path, "error.js")
      assert {:error, {exit_code, output}} = Bun.Supervisor.call(error_path, [], pool: pool)
      assert exit_code == 1
      assert output == "This is an error"
    end

    test "respects timeout option", %{pool: pool} do
      hello_path = Path.join(@fixtures_path, "hello.js")

      assert {:ok, _result} =
               Bun.Supervisor.call(hello_path, [], pool: pool, timeout: 10_000)
    end

    test "works with custom working directory", %{pool: pool} do
      hello_path = "hello.js"

      assert {:ok, result} =
               Bun.Supervisor.call(hello_path, [], pool: pool, cd: @fixtures_path)

      assert result == "Hello from bun!"
    end
  end

  describe "call!/3" do
    test "returns result on success", %{pool: pool} do
      hello_path = Path.join(@fixtures_path, "hello.js")
      assert result = Bun.Supervisor.call!(hello_path, [], pool: pool)
      assert result == "Hello from bun!"
    end

    test "raises on error", %{pool: pool} do
      error_path = Path.join(@fixtures_path, "error.js")

      assert_raise RuntimeError, ~r/Bun call failed/, fn ->
        Bun.Supervisor.call!(error_path, [], pool: pool)
      end
    end
  end

  describe "stop/1" do
    test "stops the pool" do
      {:ok, _pid} = Bun.Supervisor.start_link(name: :test_stop)
      assert :ok = Bun.Supervisor.stop(:test_stop)
    end
  end

  describe "concurrent execution" do
    test "handles multiple concurrent calls", %{pool: pool} do
      add_path = Path.join(@fixtures_path, "add.js")

      tasks =
        for i <- 1..10 do
          Task.async(fn ->
            Bun.Supervisor.call(add_path, [to_string(i), to_string(i)], pool: pool)
          end)
        end

      results = Task.await_many(tasks)

      assert Enum.all?(results, fn
               {:ok, _} -> true
               _ -> false
             end)
    end
  end
end
