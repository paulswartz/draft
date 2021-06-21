import * as React from "react";
import {
  DivisionAvailableVacationQuotaData,
  VacationDayQuotaData,
  VacationWeekQuotaData,
} from "../models/divisionVacationQuotaData";
import useDivisionAvailableVacationQuotas from "../hooks/useDivisionAvailableVacationQuotas";
import {apiSend, fetchVacationPreferenceSet} from "../api"
import { useState, useEffect } from "react";

const VacationPreferenceForm = (): JSX.Element => {
  const [selectedWeeks, setSelectedWeeks] = useState<String[]>([]);
  const [selectedDays, setSelectedDays] = useState<String[]>([]);

  const handleWeekInputChange = (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const updatedWeekPreferences = 
    event.target.checked
      ? [...selectedWeeks, event.target.value]
      : 
          selectedWeeks.filter((week) => week !== event.target.value)
        ;
    setSelectedWeeks(updatedWeekPreferences)
  };

  useEffect(() => {
  fetchVacationPreferenceSet().then((prefs) => {if (prefs != null) {setSelectedWeeks(prefs.weeks.map(pref => (pref.start_date.toString()))); setSelectedDays(prefs.days.map(pref => (pref.start_date.toString()))) }})
}, []);


    useEffect(() => {
      const ranked_weeks = selectedWeeks.map((pref, index) => ({start_date: pref, rank: index + 1}));
      const ranked_days = selectedDays.map((pref, index) => ({start_date: pref, rank: index + 1}));
    apiSend({url: "/api/vacation/preferences", method: "POST", json: JSON.stringify({weeks: ranked_weeks, days: ranked_days})})
  }, [selectedWeeks, selectedDays]);
  

  const handleDayInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    event.target.checked
      ? setSelectedDays([...selectedDays, event.target.value])
      : setSelectedDays(
          selectedDays.filter((day) => day !== event.target.value)
        );
  };

  const VacationDayDisplay = (day: VacationDayQuotaData): JSX.Element => {
    return (
      <div>
        <label>
          {day.date}{" "}
          <input
            type="checkbox"
            value={day.date}
            onChange={(e) => handleDayInputChange(e)}
          />
        </label>
      </div>
    );
  };

  const VacationWeekDisplay = (week: VacationWeekQuotaData): JSX.Element => {
    return (
      <div>
        <label>
          week of {week.start_date}{" "}
          <input
            type="checkbox"
            value={week.start_date.toString()}
            onChange={(e) => handleWeekInputChange(e)}
          />
        </label>
      </div>
    );
  };

  const availQuota: DivisionAvailableVacationQuotaData | null =
    useDivisionAvailableVacationQuotas();

  return (
    <div>
      <h3>Preferred Vacation</h3>
      <h4>Weeks</h4>
      <ul>{selectedWeeks.map((week) => (
        <li key={week.toString()}>{week}</li>
      ))}</ul>
      <h4>Days</h4>
      <ul>{selectedDays.map((day) => (
        <li key={day.toString()}>{day}</li>
      ))}</ul>
      <h3>Available Vacation Time</h3>
      <h4>Weeks</h4>
      {availQuota?.weeks.map((week) => VacationWeekDisplay(week))}

      <h4>Days</h4>
      {availQuota?.days.map((day) => VacationDayDisplay(day))}
    </div>
  );
};

export default VacationPreferenceForm;
