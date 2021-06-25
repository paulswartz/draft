export interface VacationPreference {
  start_date: string;
  end_date: string;
  rank: number;
}

export interface VacationPreferenceSet {
  days: VacationPreference[];
  weeks: VacationPreference[];
  id: number | null;
}
