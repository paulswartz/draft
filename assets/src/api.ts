import { DivisionAvailableVacationQuotaData } from "./models/divisionVacationQuotaData";
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

    export const apiSend = async <T, E>({
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
    }): Promise<Result<T, E>> => {
      const response = await fetch(url, {
        method,
        credentials: "include",
        body: json,
        headers: {
          'Content-Type': 'application/json'
        },
      })
    
      if (response.status === 204) {
        return { ok: successParser(null) }
      }
      const responseData = await response.json()
      if (response.status === 200 || response.status === 201) {
        return { ok: successParser(responseData) }
      } else if (Math.floor(response.status / 100) === 4) {
        return { error: errorParser(responseData) }
      }
    
      return Promise.reject("fetch/parse error")
    }

export const fetchDivisionAvailableVacationQuota =
  (): Promise<DivisionAvailableVacationQuotaData | null> =>
    apiCall({
      url: "/api/vacation_availability",
      parser: (divisionVacationQuotas: DivisionAvailableVacationQuotaData) =>
        divisionVacationQuotas,
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
