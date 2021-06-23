import { useEffect, useState } from "react";
import { fetchDivisionAvailableVacationQuota } from "../api";
import { DivisionAvailableVacationQuota } from "../divisionVacationQuota";
import { divisionVacationQuotaFromData } from "../models/divisionVacationQuotaData";

const useDivisionAvailableVacationQuotas =
  (): DivisionAvailableVacationQuota | null => {
    const [divisionVacationQuota, setDivisionAvailableVacationQuota] =
      useState<DivisionAvailableVacationQuota | null>(null);
    useEffect(() => {
      fetchDivisionAvailableVacationQuota().then(
        setDivisionAvailableVacationQuota
      );
    }, []);
    return divisionVacationQuota == null
      ? divisionVacationQuota
      : divisionVacationQuotaFromData(divisionVacationQuota);
  };

export default useDivisionAvailableVacationQuotas;
