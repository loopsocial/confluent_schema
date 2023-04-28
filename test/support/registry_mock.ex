defmodule RegistryMock do
  import Tesla.Mock
  alias ConfluentSchema.Registry

  def create(opts \\ []), do: opts |> Keyword.put(:adapter, Tesla.Mock) |> Registry.create()
  def create_error_subject(), do: create(base_url: "http://localhost:8081/error_subject/")
  def create_error_schema(), do: create(base_url: "http://localhost:8081/error_schema/")
  def create_error_decode(), do: create(base_url: "http://localhost:8081/error_decode/")

  def setup() do
    mock(fn
      %{method: :get, url: "http://localhost:8081/subjects"} ->
        json(["foo", "bar"])

      %{method: :get, url: "http://localhost:8081/subjects/foo/versions/latest"} ->
        json(%{"name" => "foo", "version" => 1, "schema" => "{\"type\": \"string\"}"})

      %{method: :get, url: "http://localhost:8081/subjects/bar/versions/latest"} ->
        json(%{"name" => "bar", "version" => 1, "schema" => "{\"type\": \"string\"}"})

      %{method: :get, url: "http://localhost:8081/error_subject/subjects"} ->
        %Tesla.Env{status: 404, body: "Not Found"}

      %{method: :get, url: "http://localhost:8081/error_schema/subjects"} ->
        json(["foobar"])

      %{method: :get, url: "http://localhost:8081/error_schema/subjects/foobar/versions/latest"} ->
        %Tesla.Env{status: 404, body: "Not Found"}

      %{method: :get, url: "http://localhost:8081/error_decode/subjects"} ->
        json(["foobar"])

      %{method: :get, url: "http://localhost:8081/error_decode/subjects/foobar/versions/latest"} ->
        json(%{"name" => "foobar", "version" => 1, "schema" => "invalid json"})
    end)
  end

  def set_global_subject(subject) do
    mock_global(fn
      %{method: :get, url: "http://localhost:8081/subjects"} ->
        json([subject])

      %{method: :get, url: "http://localhost:8081/subjects/" <> _schema_path} ->
        json(%{"name" => subject, "version" => 1, "schema" => "{\"type\": \"string\"}"})
    end)
  end
end
