defmodule ConfluentSchema.RegistryTest do
  use ExUnit.Case, async: true
  alias ConfluentSchema.Registry
  doctest ConfluentSchema.Registry

  setup do
    RegistryMock.setup()
    :ok
  end
end
