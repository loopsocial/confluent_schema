defmodule ConfluentSchema.CacheTest do
  use ExUnit.Case
  doctest ConfluentSchema.Cache

  setup do
    opts = [
      base_url: "https://foobar.region.aws.confluent.cloud",
      username: "key",
      password: "secret"
    ]

    start_supervised!({ConfluentSchema.Cache, opts})
    ConfluentSchema.Cache.wait_start()
  end

  describe "get/1" do
    test "get subject" do
      assert {:ok, _schema} = ConfluentSchema.Cache.get("foobar")
    end
  end
end
