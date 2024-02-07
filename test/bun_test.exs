defmodule BunTest do
  use ExUnit.Case, async: true

  @version Bun.latest_version()

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
    Application.put_env(:bun, :version, "1.0.0")

    Mix.Task.rerun("bun.install", ["--if-missing"])

    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Bun.run(:default, ["--version"]) == 0
           end) =~ "1.0.0"

    Application.delete_env(:bun, :version)

    Mix.Task.rerun("bun.install", ["--if-missing"])

    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Bun.run(:default, ["--version"]) == 0
           end) =~ @version
  after
    Application.delete_env(:bun, :version)
  end
end
