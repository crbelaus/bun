defmodule BunTest do
  use ExUnit.Case
  doctest Bun

  test "greets the world" do
    assert Bun.hello() == :world
  end
end
