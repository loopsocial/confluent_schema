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
    {:confluent_schema, "~> 0.1.2"}
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

Check out `ConfluentSchema.child_spec/1` for documentation about all options.

## Test
On `test` or `dev` environment, it is common to not have internet access. In this case,
we want to load the schemas from local files.

To achieve this, put a `subject_name.json` file inside `priv/confluent_schema/`, or run
our `confluent_schema.download` mix task, and configure your application like this:

```elixir
  # application.ex

  children = [
    {ConfluentSchema, Application.fetch_env!(:my_app, :confluent_schema)}
  ]

  # config.exs
  config :my_app, :confluent_schema, local: true, app_name: :my_app
```

Now, when `ConfluentSchema` starts, it will load the schemas from your app's `priv/confluent_schema/`
directory.
