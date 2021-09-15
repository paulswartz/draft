export interface VacationPickRoundData {
  round_id: string;
  process_id: string;
  interval_type: "week" | "day";
  employee_id: string;
  rank: number;
  cutoff_time: string;
  amount_to_force: number | null;
}
