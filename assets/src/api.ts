import { DivisionAvailableVacationQuotaData } from "./models/divisionVacationQuotaData";
import {
  VacationPreferenceSet,
  VacationPreferenceRequest,
} from "./models/vacationPreferenceSet";

interface Result<T, E> {
  ok?: T;
  error?: E;
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

export const apiSend = <T>({
  url,
  method,
  json,
  successParser = (x) => x,
}: {
  url: string;
  method: "POST" | "PATCH" | "DELETE" | "PUT";
  json: any;
  successParser?: (json: any) => T;
}): Promise<Result<T, string>> =>
  fetch(url, {
    method,
    credentials: "include",
    body: json,
    headers: {
      "Content-Type": "application/json",
    },
  })
    .then(checkResponseStatus)
    .then(parseJson)
    .then(({ data: data }: { data: any }) => {
      return { ok: successParser(data) };
    })
    .catch((error) => {
      return { error: error.message };
    });

export const fetchDivisionAvailableVacationQuota =
  (): Promise<DivisionAvailableVacationQuotaData | null> =>
    apiCall({
      url: "/api/vacation_availability",
      parser: (divisionVacationQuotas: DivisionAvailableVacationQuotaData) =>
        divisionVacationQuotas,
      defaultResult: null,
    });

export const fetchVacationPreferenceSet =
  (): Promise<VacationPreferenceSet | null> =>
    apiCall({
      url: "/api/vacation/preferences/latest",
      parser: (vacationPreferenceSet: VacationPreferenceSet) =>
        vacationPreferenceSet,
      defaultResult: null,
    });

export const updateVacationPreferences = (
  previous_preverence_set_id: number,
  preferred_weeks: VacationPreferenceRequest[],
  preferred_days: VacationPreferenceRequest[]
): Promise<Result<VacationPreferenceSet, string>> => {
  return apiSend({
    url: "/api/vacation/preferences/" + previous_preverence_set_id,
    method: "PUT",
    json: JSON.stringify({ weeks: preferred_weeks, days: preferred_days }),
  });
};

export const saveInitialVacationPreferences = (
  preferred_weeks: VacationPreferenceRequest[],
  preferred_days: VacationPreferenceRequest[]
): Promise<Result<VacationPreferenceSet, string>> => {
  return apiSend({
    url: "/api/vacation/preferences",
    method: "POST",
    json: JSON.stringify({ weeks: preferred_weeks, days: preferred_days }),
  });
};

export const upsertVacationPreferences = (
  previous_preverence_set_id: number | null,
  preferred_weeks: VacationPreferenceRequest[],
  preferred_days: VacationPreferenceRequest[]
): Promise<Result<VacationPreferenceSet, string>> => {
  return previous_preverence_set_id == null
    ? saveInitialVacationPreferences(preferred_weeks, preferred_days)
    : updateVacationPreferences(
        previous_preverence_set_id,
        preferred_weeks,
        preferred_days
      );
};
