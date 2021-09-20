defmodule DraftWeb.API.VacationAvailabilityController do
  use DraftWeb, :controller

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, %{"round_id" => round_id, "process_id" => process_id}) do
    employee_id = get_session(conn, :user_id)

    if Draft.EmployeeRanking.exists?(%{
         round_id: round_id,
         process_id: process_id,
         employee_id: employee_id
       }) do
      all_available_vacation =
        %{round_id: round_id, process_id: process_id}
        |> Draft.BidSession.vacation_session()
        |> Draft.DivisionQuota.all_available_quota_ranked(employee_id)
        |> Enum.map(&Map.take(&1, [:start_date, :end_date, :quota, :preference_rank]))
        |> Enum.sort_by(& &1.start_date, Date)

      json(conn, %{data: all_available_vacation})
    else
      conn
      |> put_status(403)
      |> json(%{
        data: "Cannot view vacation availability for given round"
      })
    end
  end
end
