import * as React from "react"
import { fetchAvailableVacationQuotas, VacationQuotaSummary } from "../ap"
import { useEffect, useState } from "react"


const VacationQuotaIndex = (): JSX.Element => {
    const useVacationQuotaSummary = (): VacationQuotaSummary | null => {
        const [availableVacationQuotas, setAvailableVacationQuotas] = useState<VacationQuotaSummary| null>(null)
        useEffect(() => {
          fetchAvailableVacationQuotas().then().then(setAvailableVacationQuotas)
        })
        return availableVacationQuotas
      }

    const availQuota: VacationQuotaSummary | null = useVacationQuotaSummary()

    
      
    return <p>There are {availQuota?.days.length} days</p>
}

export default VacationQuotaIndex
