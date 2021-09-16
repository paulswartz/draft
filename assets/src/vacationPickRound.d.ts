export interface VacationPickRoundData {
  round_id: string;
  process_id: string;
  interval_type: "week" | "day";
  employee_id: string;
  rank: number;
  cutoff_time: string;
  is_below_point_of_forcing: boolean;
}
