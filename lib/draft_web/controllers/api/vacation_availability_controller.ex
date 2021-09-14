defmodule DraftWeb.API.VacationAvailabilityController do
  use DraftWeb, :controller

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _params) do
    user_id = get_session(conn, :user_id)

    all_available_vacation =
      user_id
      |> Draft.EmployeePickOverview.get_latest()
      |> Draft.BidSession.single_session_for_round()
      |> Draft.DivisionQuota.all_available_quota_ranked(user_id)
      |> Enum.map(&Map.take(&1, [:start_date, :end_date, :quota, :preference_rank]))

    json(conn, %{data: all_available_vacation})
  end
end
