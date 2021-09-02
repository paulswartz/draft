defmodule Draft.Exporter.TempDir do
  @moduledoc """
  Draft.Exporter implementation which writes the file to System.tmp_dir().
  """
  @behaviour Draft.Exporter

  @impl Draft.Exporter
  def export(filename, iodata) do
    case System.tmp_dir() do
      nil ->
        {:error, "no temporary directory"}

      dir ->
        full_path = Path.join(dir, filename)
        File.write(full_path, iodata)
    end
  end
end
