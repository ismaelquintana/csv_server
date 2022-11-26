defmodule CsvServerTest do
  use ExUnit.Case
  doctest CsvServer

  test "greets the world" do
    assert CsvServer.hello() == :world
  end
end
