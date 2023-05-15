defmodule ConfluentSchema.ServerTest do
  use ExUnit.Case, async: false
  alias ConfluentSchema.{Cache, Server, RegistryMock}
  doctest ConfluentSchema.Server

  describe "with option `local: false`" do
    @period 10

    setup do
      RegistryMock.set_global_subject("foo")
      Server.start_link(adapter: Tesla.Mock, period: @period)
      Server.update()
      :ok
    end

    test "resets cache on start" do
      assert {:ok, _schema} = Cache.get("foo")
      assert {:error, :not_found} = Cache.get("bar")
    end

    test "allow multiple GenServers" do
      assert {:ok, pid1} = Server.start_link(name: :foo)
      assert {:ok, pid2} = Server.start_link(name: :bar)
      assert pid1 != pid2
    end

    test "manually update cache" do
      assert {:error, :not_found} = Cache.get("bar")
      RegistryMock.set_global_subject("bar")
      assert :ok = Server.update()
      Cache.get("bar")
    end

    test "periodically updates cache" do
      assert {:error, :not_found} = Cache.get("bar")
      RegistryMock.set_global_subject("bar")
      assert eventually(fn -> Cache.get("bar") end)
    end
  end

  describe "with option `local: true`" do
    test "loads schema from local files" do
      Server.start_link(local: true)
      assert eventually(fn -> Cache.get("foo") end)
    end
  end

  defp eventually(fun) do
    case fun.() do
      {:error, :not_found} -> :timer.sleep(@period) && eventually(fun)
      {:ok, _result} -> :ok
    end
  end
end
