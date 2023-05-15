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
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Manually update cache"
  def update(), do: GenServer.call(__MODULE__, :update)

  @doc false
  @spec init(Keyword.t()) :: {:ok, map, {:continue, atom()}}
  def init(opts) do
    default = [
      debug: false,
      local: false,
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
  def handle_info(:cache, state = %{local: true, app_name: app_name}) do
    schema_dir =
      app_name
      |> :code.priv_dir()
      |> Path.join("confluent_schema/")

    File.mkdir_p!(schema_dir)

    schema_dir
    |> Path.join("*.json")
    |> Path.wildcard()
    |> Enum.each(fn filename ->
      schema = filename |> File.read!() |> Jason.decode!() |> ExJsonSchema.Schema.resolve()
      filename |> Path.basename(".json") |> Cache.set(schema)
    end)

    {:noreply, state}
  end

  def handle_info(:cache, state) do
    cache(state.registry, state.debug, state.name)
    Process.send_after(self(), :cache, state.period)
    {:noreply, state}
  end

  @doc false
  def handle_call(:update, _from, state) do
    cache(state.registry, state.debug, state.name)
    {:reply, :ok, state}
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
end
