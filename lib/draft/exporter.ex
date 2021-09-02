defmodule Draft.Exporter do
  @moduledoc """
  Behavior to support exporting files out of Draft.
  """
  @callback export(filename, iodata) :: :ok | {:error, any()} when filename: String.t()

  @doc """
  Use the configured exporter to write the given file/data.
  """
  @spec export(filename, iodata) :: :ok | {:error, any()} when filename: String.t()
  def export(filename, iodata) when is_binary(filename) do
    exporter_mod = Application.get_env(:draft, :exporter)
    apply(exporter_mod, :export, [filename, iodata])
  end
end
