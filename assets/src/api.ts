import { DivisionAvailableVacationQuotaData } from "./models/divisionVacationQuotaData";

const checkResponseStatus = (response: Response) => {
  if (response.status === 200) {
    return response;
  }

  throw new Error(`Response error: ${response.status}`);
};

const parseJson = (response: Response) => response.json();

export const apiCall = <T>({
  url,
  parser,
  defaultResult,
}: {
  url: string;
  parser: (data: any) => T;
  defaultResult?: T;
}): Promise<T> =>
  fetch(url)
    .then(checkResponseStatus)
    .then(parseJson)
    .then(({ data: data }: { data: any }) => parser(data))
    .catch((error) => {
      if (defaultResult === undefined) {
        throw error;
      } else {
        return defaultResult;
      }
    });

export const fetchDivisionAvailableVacationQuota =
  (): Promise<DivisionAvailableVacationQuotaData | null> =>
    apiCall({
      url: "/api/vacation_availability",
      parser: (divisionVacationQuotas: DivisionAvailableVacationQuotaData) =>
        divisionVacationQuotas,
        defaultResult: null
    });
