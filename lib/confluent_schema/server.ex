defmodule ConfluentSchema.Server do
  @moduledoc """
  Server to periodically fetch and cache the latest Confluent schemas.
  """
  require Logger
  use GenServer
  alias ConfluentSchema.{Cache, Registry}

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

      children = [{ConfluentSchema.Server, opts}]
      Supervisor.start_link(children, strategy: :one_for_one)
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc false
  @spec init(Keyword.t()) :: {:ok, map, {:continue, atom()}}
  def init(opts) do
    default = [
      debug: false,
      name: ConfluentSchema.Cache,
      period: :timer.minutes(5),
      registry: Registry.create(opts)
    ]

    state = default |> Keyword.merge(opts) |> Map.new()
    Cache.start(state.name)
    {:ok, state, {:continue, :cache}}
  end

  @doc false
  @spec handle_continue(atom(), map()) :: {:noreply, map()}
  def handle_continue(:cache, state), do: handle_info(:cache, state)

  @doc false
  @spec handle_info(atom(), map()) :: {:noreply, map()}
  def handle_info(:cache, state) do
    cache(state.registry, state.debug, state.name)
    Process.send_after(self(), :cache, state.period)
    {:noreply, state}
  end

  defp cache(registry, debug, name) do
    case Registry.get_subject_schemas(registry) do
      {:ok, subject_schemas} ->
        Enum.each(subject_schemas, fn {subject, schema} ->
          # For performance, we cache the resolved schema.
          # https://hexdocs.pm/ex_json_schema/readme.html#resolving-a-schema
          Cache.set(subject, ExJsonSchema.Schema.resolve(schema), name)
        end)

      {:error, step, code, reason} ->
        if debug do
          Logger.debug("ConfluentSchema: #{step} failed with code #{code}: #{reason}")
        end
    end
  end

  @doc "Used on test setup to block test until server has started."
  def wait_start(), do: GenServer.call(__MODULE__, :wait_start)
  def handle_call(:wait_start, _from, state), do: {:reply, :ok, state}
end
