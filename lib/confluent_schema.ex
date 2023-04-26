defmodule ConfluentSchema do
  @moduledoc """
  Provides cache and validation for confluent schemas.
  """
  alias ConfluentSchema.Cache

  @doc """
  Validates the payload against the schema for the given subject.

  Return `{:ok, payload}` if the subject is found on cache and payload is valid.
  Return `{:error, :not_found}` if the subject is not found.
  Return `{:error, ExJsonSchema.errors()}` if the payload is invalid.
  """
  @spec validate(map, binary) :: {:ok, map} | {:error, :not_found | ExJsonSchema.errors()}
  def validate(payload, subject) do
    with {:ok, schema} <- Cache.get(subject),
         :ok <- ExJsonSchema.Validator.validate(schema, payload) do
      {:ok, payload}
    end
  end
end
