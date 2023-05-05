defmodule ConfluentSchema.Server do
  @moduledoc """
  Server to periodically fetch and cache the latest Confluent schemas.
  """
  require Logger
  use GenServer
  alias ConfluentSchema.{Cache, Registry}

  @doc "Starts the server"
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  @spec init(Keyword.t()) :: {:ok, map, {:continue, atom()}}
  def init(opts) do
    Cache.start()
    default = [debug: false, period: :timer.minutes(5), registry: Registry.create(opts)]
    state = Keyword.merge(default, opts)
    {:ok, Map.new(state), {:continue, :cache}}
  end

  @doc false
  @spec handle_continue(atom(), map()) :: {:noreply, map()}
  def handle_continue(:cache, state), do: handle_info(:cache, state)

  @doc false
  @spec handle_info(atom(), map()) :: {:noreply, map()}
  def handle_info(:cache, state) do
    cache(state.registry, state.debug)
    Process.send_after(self(), :cache, state.period)
    {:noreply, state}
  end

  defp cache(registry, debug) do
    case Registry.get_subject_schemas(registry) do
      {:ok, subject_schemas} ->
        Enum.each(subject_schemas, fn {subject, schema} ->
          # For performance, we cache the resolved schema.
          # https://hexdocs.pm/ex_json_schema/readme.html#resolving-a-schema
          Cache.set(subject, ExJsonSchema.Schema.resolve(schema))
        end)

      {:error, step, code, reason} ->
        if debug do
          Logger.debug("ConfluentSchema: #{step} failed with code #{code}: #{reason}")
        end
    end
  end

  @doc "Used on test setup to block test until server has started."
  def wait_start(), do: GenServer.call(__MODULE__, :wait_start)

  @doc false
  def handle_call(:wait_start, _from, state), do: {:reply, :ok, state}
end
