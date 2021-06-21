export interface VacationPreference {
    start_date: Date;
    end_date: Date;
    interval_type: "week" | "day";
    rank: number;
  }

  export interface VacationPreferenceSet {
    days: VacationPreference[];
    weeks: VacationPreference[];
  }

