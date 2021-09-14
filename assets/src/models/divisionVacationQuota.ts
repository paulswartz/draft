import { DivisionAvailableVacationQuotaData } from "../divisionVacationQuota";

export interface DivisionAvailableVacationQuota {
  startDate: Date;
  endDate: Date;
  quota: number;
  preferenceRank: number | null;
}

export const divisionVacationQuotaFromData = (
  divisionVacationQuotaData: DivisionAvailableVacationQuotaData[]
): DivisionAvailableVacationQuota[] =>
  divisionVacationQuotaData.map((interval) => ({
    startDate: interval.start_date,
    endDate: interval.end_date,
    quota: interval.quota,
    preferenceRank: interval.preference_rank,
  }));
