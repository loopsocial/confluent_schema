defmodule ConfluentSchema.ServerTest do
  use ExUnit.Case, async: false
  alias ConfluentSchema.{Cache, Server}
  doctest ConfluentSchema.Server
  @period 10

  setup do
    RegistryMock.set_global_subject("foo")
    Server.start_link(adapter: Tesla.Mock, period: @period)
    Server.wait_start()
  end

  test "resets cache on start" do
    assert {:ok, _schema} = Cache.get("foo")
    assert {:error, :not_found} = Cache.get("bar")
  end

  test "periodically updates cache" do
    assert {:error, :not_found} = Cache.get("bar")
    RegistryMock.set_global_subject("bar")
    assert wait_until(fn -> Cache.get("bar") end)
  end

  test "allow multiple GenServers" do
    assert {:ok, pid1} = Server.start_link(name: :foo)
    assert {:ok, pid2} = Server.start_link(name: :bar)
    assert pid1 != pid2
  end

  defp wait_until(fun) do
    case fun.() do
      {:ok, result} -> result
      _ -> :timer.sleep(@period) && wait_until(fun)
    end
  end
end
