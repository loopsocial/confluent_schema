defmodule ConfluentSchema.Registry do
  @moduledoc "Http interface for Confluent Schema."
  alias ConfluentSchemaRegistry, as: Registry

  @doc "Creates a client to interact with Confluent Schema Registry."
  @spec create(Keyword.t()) :: Tesla.Client.t()
  def create(opts), do: Registry.client(opts)

  @doc """
  Get the latest Confluent schemas from the server.
  Decode the JSON schemas into maps.

  ## Examples

      iex> ConfluentSchema.Registry.get_subject_schemas(client)
      {:ok, %{"subject" => %{type: "record", name: "MyRecord", fields: []}}}
  """
  @spec get_subject_schemas(Registry.client()) :: {:ok, map} | {:error, atom(), integer(), any()}
  def get_subject_schemas(client) do
    with {:ok, subjects} <- get_subjects(client),
         {:ok, subject_schemas} <- get_schemas(client, subjects) do
      decode(subject_schemas)
    end
  end

  defp get_subjects(client) do
    with {:error, code, reason} <- Registry.get_subjects(client) do
      {:error, :get_subjects, code, reason}
    end
  end

  defp get_schemas(client, subjects) do
    Enum.reduce_while(subjects, {:ok, %{}}, fn subject, {:ok, acc} ->
      case Registry.get_schema(client, subject) do
        {:ok, schema} -> {:cont, {:ok, Map.put(acc, subject, schema)}}
        {:error, code, reason} -> {:halt, {:error, :get_schema, code, reason}}
      end
    end)
  end

  defp decode(subject_schemas) do
    Enum.reduce_while(subject_schemas, {:ok, %{}}, fn {subject, schema}, {:ok, acc} ->
      case Jason.decode(schema["schema"]) do
        {:ok, schema} -> {:cont, {:ok, Map.put(acc, subject, schema)}}
        # Use 1 as error code to match the error code from ConfluentSchemaRegistry module.
        {:error, reason} -> {:halt, {:error, :decode_schema, 1, reason}}
      end
    end)
  end
end
