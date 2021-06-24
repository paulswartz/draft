import { useEffect, useState } from "react";
import { fetchDivisionAvailableVacationQuota, OK, Result } from "../api";
import { DivisionAvailableVacationQuota } from "../divisionVacationQuota";
import {
  DivisionAvailableVacationQuotaData,
  divisionVacationQuotaFromData,
} from "../models/divisionVacationQuotaData";

const useDivisionAvailableVacationQuotas = (): Result<
  DivisionAvailableVacationQuota,
  string
> => {
  const [divisionVacationQuotaResult, setDivisionAvailableVacationQuotaResult] =
    useState<Result<DivisionAvailableVacationQuotaData, string>>({
      status: OK,
      value: { weeks: [], days: [] },
    });
  useEffect(() => {
    fetchDivisionAvailableVacationQuota().then(
      setDivisionAvailableVacationQuotaResult
    );
  }, []);
  return divisionVacationQuotaResult.status == OK
    ? {
        status: OK,
        value: divisionVacationQuotaFromData(divisionVacationQuotaResult.value),
      }
    : divisionVacationQuotaResult;
};

export default useDivisionAvailableVacationQuotas;
