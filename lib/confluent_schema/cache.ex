defmodule ConfluentSchema.Cache do
  @moduledoc "Cache Confluent schemas on ETS table."

  @doc """
  Starts cache for Confluent schemas.
  Must be called before cache is used.
  Raise `ArgumentError` if called more than once.

  ## Example

      iex> Cache.start()
      :"#{__MODULE__}"

      iex> Cache.start()
      iex> assert_raise ArgumentError, fn -> Cache.start() end
  """
  @spec start() :: true | no_return

  def start(table_name \\ __MODULE__) do
    :ets.new(table_name, [:named_table, read_concurrency: true])
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
  def set(subject, schema, table_name \\ __MODULE__) do
    :ets.insert(table_name, {subject, schema})
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
  def get(subject, table_name \\ __MODULE__) do
    case :ets.lookup(table_name, subject) do
      [{^subject, schema}] -> {:ok, schema}
      [] -> {:error, :not_found}
    end
  end
end
