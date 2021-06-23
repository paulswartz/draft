import * as React from "react";
import {
  DivisionAvailableVacationQuotaData,
  VacationDayQuotaData,
  VacationWeekQuotaData,
} from "../models/divisionVacationQuotaData";
import useDivisionAvailableVacationQuotas from "../hooks/useDivisionAvailableVacationQuotas";
import {useVacationPreferencesReducer } from "../hooks/useVacationPreferencesReducer"
import {fetchVacationPreferenceSet, updateVacationPreferences} from "../api"
import { useEffect } from "react";



const VacationPreferenceForm = (): JSX.Element => {

  const [state, dispatch] = useVacationPreferencesReducer();

  const handleWeekInputChange = (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {

    if (state?.vacation_preference_set) {
    const updatedWeekPreferences = 
    event.target.checked
      ? [...state.vacation_preference_set.weeks, event.target.value]
      : 
          state.vacation_preference_set.weeks.filter((week) => week !== event.target.value)
        ;
        const ranked_weeks = updatedWeekPreferences.map((pref, index) => ({start_date: pref, rank: index + 1}));
        const ranked_days = state.vacation_preference_set.days.map((pref, index) => ({start_date: pref, rank: index + 1}));
        console.log(state)
        updateVacationPreferences(state.vacation_preference_set.preference_set_id, ranked_weeks, ranked_days).then((response) => {
        console.log(response); 
        if (response.ok) 
        { dispatch({type:'UPDATE_VACATION_PREFERENCES', payload: {preference_set_id: response.ok.id, weeks: response.ok.weeks.map(pref => (pref.start_date.toString())), days: response.ok.days.map(pref => (pref.start_date.toString()))}})}
        else {
          dispatch({type: 'SAVE_PREFERENCES_ERROR', payload: "Error saving preferences. Please try again"})
        }
      })
    }
      
  };

  useEffect(() => {
    fetchVacationPreferenceSet()
    .then((prefs) => {
      console.log("PREFS")
      console.log(prefs)
      if (prefs != null) {dispatch({type: "LOAD_LATEST_PREFERENCES_SUCCESS", payload: {preference_set_id: prefs.id, weeks: (prefs.weeks.map(pref => (pref.start_date.toString()))), days: prefs.days.map(pref => (pref.start_date.toString()))}})}});
  }, []);


  const handleDayInputChange = (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    if (state?.vacation_preference_set) {
    const updatedDaysPreferences = 
    event.target.checked
      ? [...state.vacation_preference_set.days, event.target.value]
      : 
      state.vacation_preference_set.days.filter((day) => day !== event.target.value)
        ;
        const ranked_days = updatedDaysPreferences.map((pref, index) => ({start_date: pref, rank: index + 1}));
        const ranked_weeks = state.vacation_preference_set.weeks.map((pref, index) => ({start_date: pref, rank: index + 1}));
        console.log(state)
        updateVacationPreferences(state.vacation_preference_set.preference_set_id, ranked_weeks, ranked_days).then((response) => {
        console.log(response); 
        if (response.ok) 
        { dispatch({type:'UPDATE_VACATION_PREFERENCES', payload: {preference_set_id: response.ok.id, weeks: response.ok.weeks.map(pref => (pref.start_date.toString())), days: response.ok.days.map(pref => (pref.start_date.toString()))}})}
        else {
          dispatch({type: 'SAVE_PREFERENCES_ERROR', payload: "Error saving preferences. Please try again"})
        }
      })
    }
      
  };

  const alreadySelectedWeek = (value: string): boolean => {
    return state != undefined && state.vacation_preference_set != undefined && state.vacation_preference_set.weeks.includes(value)
  }

  const alreadySelectedDay = (value: string): boolean => {
    return state != undefined && state.vacation_preference_set != undefined && state.vacation_preference_set.days.includes(value)
  }

  const VacationDayDisplay = (day: VacationDayQuotaData): JSX.Element => {
    return (
      <div>
        <label>
          {day.date}{" "}
          <input
            type="checkbox"
            value={day.date}
            onChange={(e) => handleDayInputChange(e)}
            checked={alreadySelectedDay(day.date.toString())}
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
            checked={alreadySelectedWeek(week.start_date.toString())}
          />
        </label>
      </div>
    );
  };

  const DisplaySelectedPreferences = (): JSX.Element => {
    return state == undefined || state.vacation_preference_set == undefined ? 
    <p>Loading selected preferences</p>
    :       <div><h3>Preferred Vacation</h3>
    <h4>Weeks</h4>
  <ul>{state.vacation_preference_set.weeks.map((week) => (
      <li key={week.toString()}>{week}</li>
    ))}</ul>
          <h4>Days</h4>
  <ul>{state.vacation_preference_set.days.map((day) => (
      <li key={day.toString()}>{day}</li>
    ))}</ul></div>
  }


  const DisplayErrorMessage = (): JSX.Element => {
    return <p> {state != undefined && state.error_msg != undefined && state.error_msg}</p> 
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
