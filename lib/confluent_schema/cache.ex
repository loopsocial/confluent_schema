defmodule ConfluentSchema.Cache do
  @moduledoc "Cache Confluent schemas on ETS table."
  @ets_table :confluent_schema_cache

  @doc """
  Starts cache for Confluent schemas.
  Must be called before cache is used.
  Raise `ArgumentError` if called more than once.

  ## Example

      iex> Cache.start()
      :#{@ets_table}

      iex> Cache.start()
      iex> assert_raise ArgumentError, fn -> Cache.start() end
  """
  @spec start() :: true | no_return
  def start() do
    :ets.new(@ets_table, [:named_table, read_concurrency: true])
  end

  @doc """
  Cache the Confluent schema for a given subject.
  Raise `ArgumentError` if cache is not started.

  ## Example

      iex> Cache.start()
      iex> Cache.set("my-subject", %{"type" => "string"})
      true

      iex> assert_raise ArgumentError, fn -> Cache.set("my-subject", %{"type" => "string"}) end
      
  """
  @spec set(binary, map) :: true | no_return
  def set(subject, schema) do
    :ets.insert(@ets_table, {subject, schema})
  end

  @doc """
  Return the cached Confluent schema for a given subject.
  Raise `ArgumentError` if cache is not started.

  ## Example

      iex> Cache.start()
      iex> Cache.set("my-subject", %{"type" => "string"})
      iex> Cache.get("my-subject")
      {:ok, %{"type" => "string"}}

      iex> Cache.start()
      iex> Cache.get("my-subject")
      {:error, :not_found}
  """
  @spec get(binary) :: {:ok, map} | {:error, :not_found} | no_return
  def get(subject) do
    case :ets.lookup(@ets_table, subject) do
      [{^subject, schema}] -> {:ok, schema}
      [] -> {:error, :not_found}
    end
  end
end
