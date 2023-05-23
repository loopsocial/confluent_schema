defmodule Mix.Tasks.ConfluentSchema.DownloadTest do
  use ExUnit.Case, async: false
  alias ConfluentSchema.RegistryMock
  alias Mix.Tasks.ConfluentSchema.Download
  @subject "download_test"

  setup do
    RegistryMock.set_global_subject(@subject)
    :ok
  end

  test "creates a file under `priv/confluent_schema/`" do
    app_name = "confluent_schema"
    localhost = "http://localhost:8081"
    args = ["--app-name", app_name, "--base-url", localhost, "--username", "", "--password", ""]

    Download.run(args)

    path =
      :confluent_schema
      |> :code.priv_dir()
      |> Path.join("confluent_schema/")
      |> Path.join(@subject <> ".json")

    assert File.exists?(path)

    File.rm!(path)
  end
end
