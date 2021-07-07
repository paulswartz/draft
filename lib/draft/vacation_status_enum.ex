defmodule Draft.VacationStatusEnum do
  @moduledoc """
  Represent supported vacation statuses, and their identifying integer value in HASTUS
  """
  use EctoEnum, assigned: 1, cancelled: 0
end
