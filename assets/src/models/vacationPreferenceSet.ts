import { intervalType } from "../vacationPreferenceSet";

export interface VacationPreference extends VacationPreferenceRequest {
  interval_type: intervalType;
}

export interface VacationPreferenceRequest {
  start_date: string;
  end_date: string;
  rank: number;
}

export interface VacationPreferenceSet {
  days: VacationPreference[];
  weeks: VacationPreference[];
  id: number | null;
}
