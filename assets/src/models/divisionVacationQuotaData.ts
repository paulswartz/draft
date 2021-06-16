import { DivisionAvailableVacationQuota } from "../divisionVacationQuota";

export interface VacationDayQuotaData {
  date: number;
  quota: number;
}

export interface VacationWeekQuotaData {
  start_date: Date;
  end_date: Date;
  quota: number;
}

export interface DivisionAvailableVacationQuotaData {
  days: VacationDayQuotaData[];
  weeks: VacationWeekQuotaData[];
}

export const divisionVacationQuotaFromData = (
  divisionVacationQuotaData: DivisionAvailableVacationQuotaData
): DivisionAvailableVacationQuota => ({
  days: divisionVacationQuotaData.days.map((day) => ({
    date: day.date,
    quota: day.quota,
  })),
  weeks: divisionVacationQuotaData.weeks.map((week) => ({
    start_date: week.start_date,
    end_date: week.end_date,
    quota: week.quota,
  })),
});
