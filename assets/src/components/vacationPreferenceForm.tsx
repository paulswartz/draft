import * as React from "react";
import {
  DivisionAvailableVacationQuotaData,
  VacationDayQuotaData,
  VacationWeekQuotaData,
} from "../models/divisionVacationQuotaData";
import useDivisionAvailableVacationQuotas from "../hooks/useDivisionAvailableVacationQuotas";
import {apiSend, fetchVacationPreferenceSet} from "../api"
import { useState, useEffect, useReducer } from "react";

function init() {
  return fetchVacationPreferenceSet()
  .then((prefs) => {if (prefs != null) return {weeks: (prefs.weeks.map(pref => (pref.start_date.toString()))), days: prefs.days.map(pref => (pref.start_date.toString()))};
  else return {weeks: [], days: []}})
}

function reducer(state, action) {
  switch (action.type) {
    case 'set_weeks':
      return  { 
        ...state,
        weeks: action.payload
    }
    case 'set_days':
      return  { 
        ...state,
        days: action.payload
    }
    case "initial_load":
    return {weeks: action.payload.weeks, days: action.payload.days}
    default:
      throw new Error();
  }
}



const VacationPreferenceForm = (): JSX.Element => {

  const [state, dispatch] = useReducer(reducer, {weeks: [], days: []});

  const handleWeekInputChange = (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const updatedWeekPreferences = 
    event.target.checked
      ? [...state.weeks, event.target.value]
      : 
          state.weeks.filter((week) => week !== event.target.value)
        ;
        const ranked_weeks = updatedWeekPreferences.map((pref, index) => ({start_date: pref, rank: index + 1}));
        const ranked_days = state.days.map((pref, index) => ({start_date: pref, rank: index + 1}));
      apiSend({url: "/api/vacation/preferences", method: "POST", json: JSON.stringify({weeks: ranked_weeks, days: ranked_days})})
      dispatch({type:'set_weeks', payload: updatedWeekPreferences })
  };

  useEffect(() => {
    fetchVacationPreferenceSet().then((prefs) => {if (prefs != null) {dispatch({type: "initial_load", payload: {weeks: (prefs.weeks.map(pref => (pref.start_date.toString()))), days: prefs.days.map(pref => (pref.start_date.toString()))}})}});
  }, []);


  const handleDayInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
  /*  event.target.checked
      ? setSelectedDays([...selectedDays, event.target.value])
      : setSelectedDays(
          selectedDays.filter((day) => day !== event.target.value)
        );
        */
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

/*   return (
    <div>
      <h3>Preferred Vacation</h3>
      <h4>Weeks</h4>
    <ul>{state.weeks.map((week) => (
        <li key={week.toString()}>{week}</li>
      ))}</ul>
      <h4>Days</h4>
      <ul>{state.weeks.map((day) => (
        <li key={day.toString()}>{day}</li>
      ))}</ul>
      <h3>Available Vacation Time</h3>
      <h4>Weeks</h4>
      {availQuota?.weeks.map((week) => VacationWeekDisplay(week))}

      <h4>Days</h4>
      {availQuota?.days.map((day) => VacationDayDisplay(day))}
    </div>
  ); */
  console.log(state)
  return (
    <div>
      <h3>Preferred Vacation</h3>
      <h4>Weeks</h4>
    <ul>{state.weeks.map((week) => (
        <li key={week.toString()}>{week}</li>
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
