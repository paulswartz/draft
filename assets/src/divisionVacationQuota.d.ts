export interface VacationDayQuota {
  date: number;
  quota: number;
}

export interface VacationWeekQuota {
  start_date: Date;
  end_date: Date;
  quota: number;
}

export interface DivisionAvailableVacationQuota {
  days: VacationDayQuota[];
  weeks: VacationWeekQuota[];
}
