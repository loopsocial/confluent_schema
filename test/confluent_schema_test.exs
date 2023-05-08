defmodule ConfluentSchemaTest do
  use ExUnit.Case, async: false
  alias ConfluentSchema.Server
  doctest ConfluentSchema

  setup do
    RegistryMock.set_global_subject("subject")
    Server.start_link(adapter: Tesla.Mock, period: 10)
    Server.update()
    :ok
  end
end
