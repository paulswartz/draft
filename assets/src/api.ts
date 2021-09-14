import { DivisionAvailableVacationQuotaData } from "./divisionVacationQuota";
import {
  DivisionAvailableVacationQuota,
  divisionVacationQuotaFromData,
} from "./models/divisionVacationQuota";
import {
  VacationPickRound,
  vacationPickRoundFromData,
} from "./models/vacationPickRound";
import {
  VacationPreferenceSet,
  VacationPreference,
  preferenceToData,
  preferenceSetFromData,
} from "./models/vacationPreferenceSet";
import { VacationPickRoundData } from "./vacationPickRound";
import { VacationPreferenceData } from "./vacationPreferenceSet";

export const OK = "ok";
export const ERROR = "error";

export type RoundKey = { roundId: string; processId: string };

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

const encodeRoundKeyParams = (roundKey: RoundKey): string =>
  `round_id=${encodeURIComponent(
    roundKey.roundId
  )}&process_id=${encodeURIComponent(roundKey.processId)}`;

export const fetchDivisionAvailableVacationQuota = (
  roundKey: RoundKey
): Promise<Result<DivisionAvailableVacationQuota[], string>> =>
  apiCall({
    url: `/api/vacation_availability?${encodeRoundKeyParams(roundKey)}`,
    parser: (divisionVacationQuotas: DivisionAvailableVacationQuotaData[]) =>
      divisionVacationQuotaFromData(divisionVacationQuotas),
  });

export const fetchLatestVacationPreferenceSet = (
  roundKey: RoundKey
): Promise<Result<VacationPreferenceSet, string>> =>
  apiCall({
    url: `/api/vacation/preferences/latest?${encodeRoundKeyParams(roundKey)}`,
    parser: (vacationPreferenceSet) =>
      preferenceSetFromData(vacationPreferenceSet),
  });

export const fetchVacationPickOverview = (): Promise<
  Result<VacationPickRound, string>
> =>
  apiCall({
    url: "/api/vacation/pick_overview",
    parser: (overview: VacationPickRoundData) =>
      vacationPickRoundFromData(overview),
  });

export const updateVacationPreferences = (
  roundId: string,
  processId: string,
  previous_preverence_set_id: number,
  preferences: VacationPreferenceData[]
): Promise<Result<VacationPreferenceSet, string>> => {
  return apiSend({
    url: "/api/vacation/preferences/" + previous_preverence_set_id,
    method: "PUT",
    json: JSON.stringify({
      round_id: roundId,
      process_id: processId,
      preferences: preferences,
    }),
    successParser: (preferenceSet) => preferenceSetFromData(preferenceSet),
  });
};

const saveInitialVacationPreferences = (
  roundId: string,
  processId: string,
  preferences: VacationPreferenceData[]
): Promise<Result<VacationPreferenceSet, string>> => {
  return apiSend({
    url: "/api/vacation/preferences",
    method: "POST",
    json: JSON.stringify({
      round_id: roundId,
      process_id: processId,
      preferences: preferences,
    }),
    successParser: (preferenceSet) => preferenceSetFromData(preferenceSet),
  });
};

export const upsertVacationPreferences = (
  roundId: string,
  processId: string,
  previousPreferenceSetId: number | null,
  preferences: VacationPreference[]
): Promise<Result<VacationPreferenceSet, string>> => {
  const preferenceData = preferences.map((pref) => preferenceToData(pref));
  return previousPreferenceSetId == null
    ? saveInitialVacationPreferences(roundId, processId, preferenceData)
    : updateVacationPreferences(
        roundId,
        processId,
        previousPreferenceSetId,
        preferenceData
      );
};
