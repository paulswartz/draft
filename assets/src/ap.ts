export interface VacationDayQuota {
  date: number;
  quota: number;
}

export interface VacationWeekQuota {
  start_date: Date;
  end_date: Date;
  quota: number;
}

export interface VacationQuotaSummary {
  days: VacationDayQuota[];
  weeks: VacationWeekQuota[];
}


const checkResponseStatus = (response: Response) => {
  if (response.status === 200) {
    return response
  }

  throw new Error(`Response error: ${response.status}`)
}

const parseJson = (response: Response) => response.json()

export const apiCall = <T>({
  url,
  parser,
  defaultResult,
}: {
  url: string
  parser: (data: any) => T
  defaultResult?: T
}): Promise<T> =>
  fetch(url)
    .then(checkResponseStatus)
    .then(parseJson)
    .then(({ data: data }: { data: any }) => parser(data))
    .catch((error) => {
      if (defaultResult === undefined) {
        throw error
      } else {
        return defaultResult
      }
    })

export const fetchAvailableVacationQuotas = (): Promise<VacationQuotaSummary> =>
  apiCall({
    url: "/api/vacation_availability",
    parser: (vacationQuotaSummary: VacationQuotaSummary) => vacationQuotaSummary
  })
