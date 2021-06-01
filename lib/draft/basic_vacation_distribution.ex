defmodule Draft.BasicVacationDistribution do
  alias Draft.BidGroup
  alias Draft.BidRound
  alias Draft.EmployeeRanking
  alias Draft.EmployeeVacationQuota
  alias Draft.Repo

  import Ecto.Query
  require Logger

  def basic_vacation_distribution() do
    bid_rounds = Repo.all(from r in BidRound, order_by: [asc: r.rank, asc: r.round_opening_date])
    Enum.each(bid_rounds, &assign_vacation_for_round(&1))
  end

  def assign_vacation_for_round(round) do
  Logger.info("STARTING NEW ROUND: #{round.rank} - #{round.division_id} - #{round.division_description} (picking between #{round.round_opening_date} and #{round.round_closing_date})\n")
  bid_groups = Repo.all(from g in BidGroup, where: g.round_id == ^round.round_id and g.process_id == ^round.process_id,  order_by: [asc: g.group_number])
  Enum.each(bid_groups, &assign_vacation_for_group(&1))
  end

  def assign_vacation_for_group(group) do
    Logger.info("STARTING NEW GROUP: #{group.group_number} (cutoff time #{group.cutoff_datetime})\n")
    group_employees = Repo.all(from e in EmployeeRanking, where: e.round_id == ^group.round_id and e.process_id == ^group.process_id and e.group_number == ^group.group_number,  order_by: [asc: e.rank])
    Enum.each(group_employees, &assign_vacation_for_employee(&1, group.cutoff_datetime))

  end



  def assign_vacation_for_employee(employee, cutoff_datetime) do
    Logger.info("Distributing vacation for employee #{employee.rank} - #{employee.employee_id}")
    employee_balances = Repo.all(from q in EmployeeVacationQuota, where: q.employee_id == ^employee.employee_id and q.interval_start_date < ^cutoff_datetime and q.interval_end_date >= ^cutoff_datetime)

    if length(employee_balances) == 1 do
      employee_balance = List.first(employee_balances)
    Logger.info("Employee #{employee.employee_id} balance for period #{employee_balance.interval_start_date} - #{employee_balance.interval_end_date}: #{employee_balance.weekly_quota} max weeks, #{employee_balance.dated_quota} max days, #{employee_balance.maximum_minutes} max minutes\n")
  end

  end



end
