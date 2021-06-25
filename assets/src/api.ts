import { DivisionAvailableVacationQuotaData } from "./models/divisionVacationQuotaData";
import {
  VacationPreferenceSet,
  VacationPreference,
} from "./models/vacationPreferenceSet";

export const OK = "ok";
export const ERROR = "error";

type ResultOk<T> = { status: typeof OK; value: T };
type ResultError<E> = { status: typeof ERROR; value: E };

export type Result<T, E> = ResultOk<T> | ResultError<E>;

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
}: {
  url: string;
  parser: (data: any) => T;
}): Promise<Result<T, string>> =>
  fetch(url)
    .then(checkResponseStatus)
    .then(parseJson)
    .then(({ data: dataToParse }: { data: any }): ResultOk<T> => {
      return { status: OK, value: parser(dataToParse) };
    })
    .catch((error) => {
      return { status: ERROR, value: error.message };
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
}): Promise<Result<T, string>> => {
  const csrfToken = document.head.querySelector(
    "[name~=csrf-token][content]"
  ) as HTMLMetaElement;
  return fetch(url, {
    method,
    credentials: "include",
    body: json,
    headers: {
      "Content-Type": "application/json",
      "x-csrf-token": csrfToken.content,
    },
  })
    .then(checkResponseStatus)
    .then(parseJson)
    .then(({ data: dataToParse }: { data: any }): ResultOk<T> => {
      return { status: OK, value: successParser(dataToParse) };
    })
    .catch((error) => {
      return { status: ERROR, value: error.message };
    });
};

export const fetchDivisionAvailableVacationQuota = (): Promise<
  Result<DivisionAvailableVacationQuotaData, string>
> =>
  apiCall({
    url: "/api/vacation_availability",
    parser: (divisionVacationQuotas: DivisionAvailableVacationQuotaData) =>
      divisionVacationQuotas,
  });

export const fetchLatestVacationPreferenceSet = (): Promise<
  Result<VacationPreferenceSet, string>
> =>
  apiCall({
    url: "/api/vacation/preferences/latest",
    parser: (vacationPreferenceSet: VacationPreferenceSet) =>
      vacationPreferenceSet,
  });

export const updateVacationPreferences = (
  previous_preverence_set_id: number,
  preferred_weeks: VacationPreference[],
  preferred_days: VacationPreference[]
): Promise<Result<VacationPreferenceSet, string>> => {
  return apiSend({
    url: "/api/vacation/preferences/" + previous_preverence_set_id,
    method: "PUT",
    json: JSON.stringify({ weeks: preferred_weeks, days: preferred_days }),
  });
};

export const saveInitialVacationPreferences = (
  preferred_weeks: VacationPreference[],
  preferred_days: VacationPreference[]
): Promise<Result<VacationPreferenceSet, string>> => {
  return apiSend({
    url: "/api/vacation/preferences",
    method: "POST",
    json: JSON.stringify({ weeks: preferred_weeks, days: preferred_days }),
  });
};

export const upsertVacationPreferences = (
  previous_preverence_set_id: number | null,
  preferred_weeks: VacationPreference[],
  preferred_days: VacationPreference[]
): Promise<Result<VacationPreferenceSet, string>> => {
  return previous_preverence_set_id == null
    ? saveInitialVacationPreferences(preferred_weeks, preferred_days)
    : updateVacationPreferences(
        previous_preverence_set_id,
        preferred_weeks,
        preferred_days
      );
};
