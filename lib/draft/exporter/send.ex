defmodule Draft.Exporter.Send do
  @moduledoc """
  Draft.Exporter which sends a message with the filename/contents to the current process.

  Used for testing, where the unit test can `assert_received` that the right contents were "written".
  """
  @behaviour Draft.Exporter

  @impl Draft.Exporter
  def export(filename, iodata) do
    send(self(), {__MODULE__, filename, iodata})
    :ok
  end
end
