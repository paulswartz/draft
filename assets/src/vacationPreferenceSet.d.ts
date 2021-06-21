export interface VacationPreference {
    start_date: Date;
    end_date: Date;
    interval_type: string;
    rank: number;
  }
  
  export interface VacationPreferenceSet {
    process_id: string;
    round_id: string;
    employee_id: string;
    vacation_preferences: VacationPreference[]
  }
