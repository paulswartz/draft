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
        weeks: action.payload.weeks,
        days: action.payload.weeks,
        preference_set_id: action.payload.id
    }
    case 'save_preferences_error':
      return  { 
        ...state,
        error_msg: action.payload
    }
    case "initial_load":
    return {weeks: action.payload.weeks, days: action.payload.days, preference_set_id: action.payload.id}
    default:
      throw new Error();
  }
}



const VacationPreferenceForm = (): JSX.Element => {

  const [state, dispatch] = useReducer(reducer, undefined);

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
      apiSend({url: "/api/vacation/preferences", method: "POST", json: JSON.stringify({previous_preference_set_id: state.preference_set_id, weeks: ranked_weeks, days: ranked_days})})
      .then((response) => {
        console.log(response); 
        if (response.ok) 
        { dispatch({type:'set_weeks', payload: {weeks: response.ok.weeks.map(pref => (pref.start_date.toString())), days: response.ok.map(pref => (pref.start_date.toString()))}})}
        else {
          dispatch({type: 'save_preferences_error', payload: "Error saving preferences. Please try again"})
        }
      })
      
  };

  useEffect(() => {
    fetchVacationPreferenceSet()
    .then((prefs) => {if (prefs != null) {dispatch({type: "initial_load", payload: {weeks: (prefs.weeks.map(pref => (pref.start_date.toString()))), days: prefs.days.map(pref => (pref.start_date.toString()))}})}});
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

  const DisplaySelectedPreferences = (): JSX.Element => {
    return state == undefined ? 
    <p>Loading selected preferences</p>
    :       <div><h3>Preferred Vacation</h3>
    <h4>Weeks</h4>
  <ul>{state.weeks.map((week) => (
      <li key={week.toString()}>{week}</li>
    ))}</ul>
          <h4>Days</h4>
  <ul>{state.days.map((day) => (
      <li key={day.toString()}>{day}</li>
    ))}</ul></div>
  }


  const DisplayErrorMessage = (): JSX.Element => {
    return state != undefined && state.error_msg && <p> state.error_msg</p>
  }


  const availQuota: DivisionAvailableVacationQuotaData | null =
    useDivisionAvailableVacationQuotas();

  return (
    <div>
      {DisplayErrorMessage()}
{DisplaySelectedPreferences()}
      <h3>Available Vacation Time</h3>
      <h4>Weeks</h4>
      {availQuota?.weeks.map((week) => VacationWeekDisplay(week))}

      <h4>Days</h4>
      {availQuota?.days.map((day) => VacationDayDisplay(day))}
    </div>
  );
};

export default VacationPreferenceForm;
