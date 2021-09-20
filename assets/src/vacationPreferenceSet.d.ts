export interface VacationPreferenceData {
  start_date: string;
  end_date: string;
  rank: number;
}

export interface VacationPreferenceSetData {
  process_id: string;
  round_id: string;
  employee_id: string;
  id: number;
  preferences: VacationPreferenceData[];
}
