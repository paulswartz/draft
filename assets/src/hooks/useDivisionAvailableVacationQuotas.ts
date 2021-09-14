import { useEffect, useState } from "react";
import { fetchDivisionAvailableVacationQuota, OK, Result } from "../api";
import { DivisionAvailableVacationQuota } from "../models/divisionVacationQuota";
import { VacationPickRound } from "../models/vacationPickRound";

const useDivisionAvailableVacationQuotas = (
  pickOverview: VacationPickRound
): Result<DivisionAvailableVacationQuota[], string> => {
  const [divisionVacationQuotaResult, setDivisionAvailableVacationQuotaResult] =
    useState<Result<DivisionAvailableVacationQuota[], string>>({
      status: OK,
      value: [],
    });
  useEffect(() => {
    fetchDivisionAvailableVacationQuota(pickOverview).then(
      setDivisionAvailableVacationQuotaResult
    );
  }, []);
  return divisionVacationQuotaResult;
};

export default useDivisionAvailableVacationQuotas;
