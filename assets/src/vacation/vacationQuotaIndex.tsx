import * as React from "react"
import { fetchAvailableVacationQuotas, VacationQuotaSummary, VacationDayQuota, VacationWeekQuota } from "../ap"
import { useEffect, useState } from "react"


const VacationDayDisplay = (day: VacationDayQuota): JSX.Element => {
    return <p>{day.date}, quota: {day.quota}</p>
}

const VacationWeekDisplay = (week: VacationWeekQuota): JSX.Element => {
    return <p>{week.start_date} through {week.end_date}, quota: {week.quota}</p>
}

const VacationQuotaIndex = (): JSX.Element => {
    const useVacationQuotaSummary = (): VacationQuotaSummary | null => {
        const [availableVacationQuotas, setAvailableVacationQuotas] = useState<VacationQuotaSummary| null>(null)
        useEffect(() => {
          fetchAvailableVacationQuotas().then(setAvailableVacationQuotas)
        }, [])
        return availableVacationQuotas
      }

    const availQuota: VacationQuotaSummary | null = useVacationQuotaSummary()

    
      
    return <div> <h3>Days</h3>
    {<p>{availQuota?.days.map(day => {return VacationDayDisplay(day)})}</p>}
    <h3>Weeks</h3>
    {<p>{availQuota?.weeks.map(week => {return VacationWeekDisplay(week)})}</p>}
    </div>
}



export default VacationQuotaIndex
