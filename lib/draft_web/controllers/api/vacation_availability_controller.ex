defmodule DraftWeb.API.VacationAvailabilityController do
  use DraftWeb, :controller

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _params) do
    pick_overview =
      conn
      |> get_session(:user_id)
      |> Draft.EmployeePickOverview.get_latest()

    all_available_vacation = %{
      days:
        Draft.DivisionVacationDayQuota.all_available_days(
          pick_overview.job_class,
          pick_overview.process_id,
          pick_overview.round_id
        ),
      weeks:
        Draft.DivisionVacationWeekQuota.all_available_weeks(
          pick_overview.job_class,
          pick_overview.process_id,
          pick_overview.round_id
        )
    }

    json(conn, %{data: all_available_vacation})
  end
end
