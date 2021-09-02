defmodule Draft.Exporter.S3 do
  @moduledoc """
  Draft.Exporter which writes to an S3 bucket.

  Configuration required:
  - bucket
  - prefix
  """

  @behaviour Draft.Exporter

  @impl Draft.Exporter
  def export(filename, iodata) do
    config = Application.get_env(:draft, __MODULE__)
    full_path = "#{config[:prefix]}/#{filename}"

    case ExAws.request(
           ExAws.S3.put_object(config[:bucket], full_path, IO.iodata_to_binary(iodata))
         ) do
      {:ok, _ignored} ->
        :ok

      {:error, e} ->
        {:error, e}
    end
  end
end
