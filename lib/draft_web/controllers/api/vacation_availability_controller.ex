defmodule DraftWeb.API.VacationAvailabilityController do
  use DraftWeb, :controller

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _params) do
    latest_ranking = Draft.EmployeeRanking.get_latest_ranking(get_session(conn, :user_id))
    all_available_vacation = %{days: Draft.DivisionVacationDayQuota.all_available_days(latest_ranking.division_id, latest_ranking.job_class),
  weeks: Draft.DivisionVacationWeekQuota.all_available_weeks(latest_ranking.division_id, latest_ranking.job_class)}
    json(conn, %{data: all_available_vacation})
  end
end
