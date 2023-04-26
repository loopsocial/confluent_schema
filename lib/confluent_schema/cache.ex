defmodule ConfluentSchema.Cache do
  @moduledoc """
  Server to periodically fetch and cache the latest Confluent schemas.
  """
  use GenServer
  require Logger

  @ets_table :confluent_schema_cache

  @doc """
  Return the cached Confluent schema for a given subject.
  Raise `RuntimeError` if the server is not started.

  ## Example

      iex> ConfluentSchema.Cache.get("my-subject")
      {:error, :not_found}
  """
  @spec get(binary) :: {:ok, map} | {:error, :not_found}
  def get(subject) do
    try do
      case :ets.lookup(@ets_table, subject) do
        [{^subject, schema}] -> {:ok, schema}
        [] -> {:error, :not_found}
      end
    rescue
      ArgumentError -> raise "#{__MODULE__} is not started"
    end
  end

  def wait_start() do
    GenServer.call(ConfluentSchema.Cache, :wait_start)
  end

  @doc """
  Start a server to periodically fetch and cache Confluent schemas.

  You can get credentials from [Confluent Cloud](https://confluent.cloud): Login > Home > Environments.
  Or you can also spin off your own Confluent Schema Registry server.

  ## Options

    * `period` - Period to update schemas (optional, default 5 minutes)
    * `debug` - Enable debug logs (optional, default false)

  ## ConfluentSchemaRegistry options

    * `base_url` - URL of schema registry (optional, default "http://localhost:8081")
    * `username` - username for BasicAuth (optional)
    * `password` - password for BasicAuth (optional)
    * `adapter` - Tesla adapter config (optional)
    * `middleware` - List of additional ConfluentSchemaRegistry middlewares (optional)

  ## Example

      opts = [
        base_url: "https://foobar.region.aws.confluent.cloud",
        username: "key",
        password: "secret"
      ]

      children = [{ConfluentSchema.Cache, opts}]
      Supervisor.start_link(children, strategy: :one_for_one)
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    defaults = [period: :timer.minutes(5), debug: false]
    keys = [:period, :debug, :base_url, :username, :password, :adapter, :middleware]
    opts = defaults |> Keyword.merge(opts) |> Keyword.take(keys)

    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  @spec init(Keyword.t()) :: {:ok, map, {:continue, atom()}}
  def init(opts) do
    client = ConfluentSchemaRegistry.client(opts)
    state = %{config: Map.new(opts), client: client}

    :ets.new(@ets_table, [:named_table, read_concurrency: true])
    periodically_cache(state.config.period)

    {:ok, state, {:continue, :cache}}
  end

  @doc false
  @spec handle_continue(atom(), map()) :: {:noreply, map()}
  def handle_continue(:cache, state) do
    cache(state)
    {:noreply, state}
  end

  @doc false
  @spec handle_info(atom(), map()) :: {:noreply, map()}
  def handle_info(:cache, state) do
    cache(state)
    periodically_cache(state.config.period)

    {:noreply, state}
  end

  defp cache(state) do
    case ConfluentSchemaRegistry.get_subjects(state.client) do
      {:ok, subjects} -> cache_subjects(state, subjects)
      {:error, code, reason} -> debug(state, "get_subjects", code, reason)
    end
  end

  defp cache_subjects(state, subjects) do
    for subject <- subjects do
      case ConfluentSchemaRegistry.get_schema(state.client, subject) do
        {:ok, schema} -> resolve_and_cache(state, subject, schema["schema"])
        {:error, code, reason} -> debug(state, "get_schema", code, reason)
      end
    end
  end

  defp resolve_and_cache(state, subject, schema) do
    case Jason.decode(schema) do
      {:ok, schema} -> :ets.insert(@ets_table, {subject, ExJsonSchema.Schema.resolve(schema)})
      {:error, reason} -> debug(state, "json_decode", 1, reason)
    end
  end

  defp debug(state, step, code, reason) do
    if state.config.debug do
      Logger.debug("ConfluentSchemaRegistry #{step} error (#{code}): #{reason}")
    end
  end

  defp periodically_cache(period) do
    Process.send_after(self(), :cache, period)
  end

  @doc "Used on tests to block test until server start."
  def handle_call(:wait_start, _from, state), do: {:reply, :ok, state}
end
