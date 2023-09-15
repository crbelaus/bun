defmodule ElixirBunTest do
  use ExUnit.Case
  doctest ElixirBun

  test "greets the world" do
    assert ElixirBun.hello() == :world
  end
end
