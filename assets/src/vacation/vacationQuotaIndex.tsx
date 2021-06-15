import * as React from "react"
import { fetchAvailableVacationQuotas, VacationQuotaSummary, VacationDayQuota, VacationWeekQuota } from "../api"
import { useEffect, useState } from "react"

const VacationQuotaIndex = (): JSX.Element => {
  const [selectedWeeks, setSelectedWeeks] = useState<String[] | []>([])
  const [selectedDays, setSelectedDays] = useState<String[] | []>([])

  const handleWeekInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    event.target.checked ?
      setSelectedWeeks([...selectedWeeks, event.target.value])
      : setSelectedWeeks(selectedWeeks.filter(week => week !== event.target.value))
  }


  const handleDayInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    event.target.checked ?
      setSelectedDays([...selectedDays, event.target.value])
      : setSelectedDays(selectedDays.filter(day => day !== event.target.value))
  }

  const VacationDayDisplay = (day: VacationDayQuota): JSX.Element => {
    return <div><input type="checkbox" value={day.date} onChange={(e) => handleDayInputChange(e)}></input> <p>{day.date}, quota: {day.quota}</p></div>
  }

  const VacationWeekDisplay = (week: VacationWeekQuota): JSX.Element => {
    return <div><input type="checkbox" value={week.start_date.toString()} onChange={(e) => handleWeekInputChange(e)} ></input> <p> week of {week.start_date}, quota: {week.quota}</p></div>
  }



  const useVacationQuotaSummary = (): VacationQuotaSummary | null => {
    const [availableVacationQuotas, setAvailableVacationQuotas] = useState<VacationQuotaSummary | null>(null)
    useEffect(() => {
      fetchAvailableVacationQuotas().then(setAvailableVacationQuotas)
    }, [])
    return availableVacationQuotas
  }

  const availQuota: VacationQuotaSummary | null = useVacationQuotaSummary()



  return <div>
    <h3>Selections</h3>
    <h4>Weeks</h4>
    {selectedWeeks.map(week => { return <p>{week}</p> })}
    <h4>Days</h4>
    {selectedDays.map(day => { return <p>{day}</p> })}
    <h3>Weeks</h3>
    {availQuota?.weeks.map(week => { return VacationWeekDisplay(week) })}

    <h3>Days</h3>
    {availQuota?.days.map(day => { return VacationDayDisplay(day) })}

  </div>
}



export default VacationQuotaIndex
