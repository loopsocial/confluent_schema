# ConfluentSchema

Provides cache and validation for confluent schemas that are pulled from a registry.

It mixes 

* [ConfluentSchemaRegistry](https://github.com/cogini/confluent_schema_registry)
* [ExJsonSchema](https://github.com/jonasschmidt/ex_json_schema/)
* [ETS](https://www.erlang.org/doc/man/ets.html)

To provide fast validation for schemas registered remotely on a registry server, for example [confluent.cloud](confluent.cloud).

## Installation

```elixir
def deps do
  [
    {:confluent_schema, "~> 0.1.0"}
  ]
end
```

## Usage
On `application.ex`:

```elixir
  def start(_type, _args) do
    opts = [
      period: :timer.seconds(10),
      debug: true,
      base_url: "https://foobar.region.aws.confluent.cloud",
      username: "key",
      password: "api secret",
    ]

    children = [
      {ConfluentSchema, opts}
    ]

    supervisor_opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, supervisor_opts)
  end
```

Then you can use confluent schema registry to validate payloads for a subject:

```elixir
payload = %{foo: "bar"}
ConfluentSchema.validate(payload, "my-subject")
```

Check out `ConfluentSchema.start_link/1` for documentation about all the options.
Use the `period` option to customize the interval to refresh schemas on the cache. It is 5 minutes by default.
Use the `debug` option to log errors in case schemas aren't correctly fetched from the registry.
