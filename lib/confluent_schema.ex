defmodule ConfluentSchema do
  @moduledoc """
  Provides cache and validation for confluent schemas.
  """
  alias ConfluentSchema.{Cache, Server}
  alias ExJsonSchema.Validator

  @type errors :: [{message :: binary, path :: binary}]

  @doc """
  Validates the payload against the schema for the given subject.
  If you need to validate against multiple schema registries, use the `cache_name` option.

  ## Examples

      iex> ConfluentSchema.validate("a string example", "subject")
      {:ok, "a string example"}

      iex> ConfluentSchema.validate("a string example", "unknown-subject")
      {:error, :not_found}

      iex> ConfluentSchema.validate(123, "subject")
      {:error, [{"Type mismatch. Expected String but got Integer.", "#"}]}
  """
  @spec validate(map, binary, atom()) ::
          {:ok, map} | {:error, :not_found} | {:error, errors} | no_return
  def validate(payload, subject, cache_name \\ ConfluentSchema.Cache) do
    with {:ok, schema} <- Cache.get(subject, cache_name),
         :ok <- Validator.validate(schema, payload) do
      {:ok, payload}
    end
  end

  @doc """
  Returns a `Supervisor.child_spec()` for server to periodically fetch and cache Confluent schemas.

  You can get credentials from [Confluent Cloud](https://confluent.cloud): Login > Home > Environments.
  Or you can also spin off your own Confluent Schema Registry server.

  ## Options

    * `period` - Period in milliseconds to update schemas (optional integer, default 5 minutes)
    * `debug` - Enable debug logs (optional boolean, default false)
    * `name` - Name of the GenServer and ETS cache, (optional atom)  
    Useful when multiple schema registries are needed.  
    (default `ConfluentSchema.Server` for the GenServer and `ConfluentSchema.Cache` for the ETS table)

  ## [ConfluentSchemaRegistry](https://hexdocs.pm/confluent_schema_registry/) options

    * `base_url` - URL of schema registry (optional, default "http://localhost:8081")
    * `username` - username or api key (optional)
    * `password` - password or api secret (optional)
    * `adapter` - Tesla Adapter (optional, default `Tesla.Adapter.Hackney`)
    * `middleware` - List of [Tesla middlewares](https://hexdocs.pm/tesla/readme.html#middleware) (optional)
    * `local` - Whether to use local schemas from `priv/confluent_schema/*.json`  
    (optional, default false when set all above options are ignored)
    * `app_name` - Name of the application where local schemas are
    (required only if local is true)

  ## Example

       opts = [
        name: :my_custom_registry,
        period: :timer.minutes(5),
        debug: false,
        base_url: "http://localhost:8081",
        username: "key",
        password: "api secret",
        adapter: {Tesla.Adapter.Hackney, hackney_opts},
        middleware: []
      ]

      children = [{ConfluentSchema, opts}]
      Supervisor.start_link(children, strategy: :one_for_one)
  """
  @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: Server,
      start: {Server, :start_link, [opts]}
    }
  end
end
