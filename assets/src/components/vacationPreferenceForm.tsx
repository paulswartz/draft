import * as React from "react";
import {
  DivisionAvailableVacationQuotaData,
  VacationDayQuotaData,
  VacationWeekQuotaData,
} from "../models/divisionVacationQuotaData";
import useDivisionAvailableVacationQuotas from "../hooks/useDivisionAvailableVacationQuotas";
import { useState } from "react";

const VacationPreferenceForm = (): JSX.Element => {
  const [selectedWeeks, setSelectedWeeks] = useState<String[]>([]);
  const [selectedDays, setSelectedDays] = useState<String[]>([]);

  const handleWeekInputChange = (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    event.target.checked
      ? setSelectedWeeks([...selectedWeeks, event.target.value])
      : setSelectedWeeks(
          selectedWeeks.filter((week) => week !== event.target.value)
        );
  };

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
