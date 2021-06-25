export type intervalType = "week" | "day";

export interface VacationPreference {
  start_date: Date;
  end_date: Date;
  interval_type: intervalType;
  rank: number;
}

export interface VacationPreferenceSet {
  process_id: string;
  round_id: string;
  employee_id: string;
  id: number;
  vacation_preferences: VacationPreference[];
}
