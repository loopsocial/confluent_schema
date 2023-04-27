defmodule ConfluentSchema.ServerTest do
  use ExUnit.Case
  doctest ConfluentSchema.Server

  setup do
    opts = [
      base_url: "https://foobar.region.aws.confluent.cloud",
      username: "key",
      password: "secret"
    ]

    start_supervised!({ConfluentSchema.Server, opts})
    ConfluentSchema.Server.wait_start()
  end

  @tag :skip
  test "periodically updates cache" do
  end
end
