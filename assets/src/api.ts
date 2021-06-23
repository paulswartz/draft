import { DivisionAvailableVacationQuotaData } from "./models/divisionVacationQuotaData";
import { VacationPreferenceSet } from "./models/vacationPreferenceSet";

interface Result<T, E> {
  ok?: T
  error?: E
}

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

    export const apiSend = <T, E>({
      url,
      method,
      json,
      successParser = (x) => x,
      errorParser = (x) => x,
    }: {
      url: string
      method: "POST" | "PATCH" | "DELETE"
      json: any
      successParser?: (json: any) => T
      errorParser?: (json: any) => E
    }): Promise<Result<T, E>> => 
      fetch(url, {
        method,
        credentials: "include",
        body: json,
        headers: {
          'Content-Type': 'application/json'
        },
      }).then(parseJson)
      .then(({ data: data }: { data: any }) => {return {ok: successParser(data)}})
      .catch((error) => {return {error: errorParser(error)}});
    

export const fetchDivisionAvailableVacationQuota =
  (): Promise<DivisionAvailableVacationQuotaData | null> =>
    apiCall({
      url: "/api/vacation_availability",
      parser: (divisionVacationQuotas: DivisionAvailableVacationQuotaData) =>
        divisionVacationQuotas,
        defaultResult: null
    });

    export const fetchVacationPreferenceSet =
    (): Promise<VacationPreferenceSet | null> =>
      apiCall({
        url: "/api/vacation/preferences",
        parser: (vacationPreferenceSet: VacationPreferenceSet) =>
        vacationPreferenceSet,
          defaultResult: null
      });

    export const updateVacationPreferences =
    (): Promise<DivisionAvailableVacationQuotaData | null> =>
      apiCall({
        url: "/api/vacation_availability",
        parser: (divisionVacationQuotas: DivisionAvailableVacationQuotaData) =>
          divisionVacationQuotas,
          defaultResult: null
      });
