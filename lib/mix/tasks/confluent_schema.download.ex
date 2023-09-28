defmodule Mix.Tasks.ConfluentSchema.Download do
  @shortdoc "Download schemas from a Registry server to `priv/confluent_schema/`."
  @usage """
    mix confluent_schema.download \\
        --app-name my_app \\
        --username API_KEY \\
        --password API_SECRET \\
        --base-url https://foobar.region.aws.confluent.cloud
  """

  @moduledoc """
  #{@shortdoc}

  ## Example

    #{@usage}
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    options = [app_name: :string, base_url: :string, password: :string, username: :string]
    {args, _argv} = OptionParser.parse!(args, strict: options)
    args = if Mix.env() == :test, do: Keyword.put(args, :adapter, Tesla.Mock), else: args

    schema_dir =
      args
      |> Keyword.fetch!(:app_name)
      |> String.to_existing_atom()
      |> :code.priv_dir()
      |> Path.join("confluent_schema/")

    File.mkdir_p!(schema_dir)

    # Download schemas from Confluent Schema Registry
    {:ok, subject_schemas} =
      args
      |> ConfluentSchema.Registry.create()
      |> ConfluentSchema.Registry.get_subject_schemas()

    # Create schema files
    Enum.each(subject_schemas, fn {subject, schema} ->
      schema_dir
      |> Path.join(subject <> ".json")
      |> File.write!(Jason.encode!(schema))
    end)
  end
end
