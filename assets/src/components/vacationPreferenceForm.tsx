import * as React from "react";
import {
  DivisionAvailableVacationQuotaData,
  VacationDayQuotaData,
  VacationWeekQuotaData,
} from "../models/divisionVacationQuotaData";
import useDivisionAvailableVacationQuotas from "../hooks/useDivisionAvailableVacationQuotas";
import { useVacationPreferencesReducer } from "../hooks/useVacationPreferencesReducer";
import {
  fetchLatestVacationPreferenceSet,
  OK,
  Result,
  upsertVacationPreferences,
} from "../api";
import { useEffect } from "react";
import {
  VacationPreferenceRequest,
  VacationPreferenceSet,
} from "../models/vacationPreferenceSet";

const VacationPreferenceForm = (): JSX.Element => {
  const [state, dispatch] = useVacationPreferencesReducer();

  const handleWeekInputChange = (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const [selectedStartDate, selectedEndDay] = event.target.value.split(":");
    if (state?.vacation_preference_set) {
      const updatedWeeksPreferences = event.target.checked
        ? [
            ...state.vacation_preference_set.weeks,
            {
              start_date: selectedStartDate,
              end_date: selectedEndDay,
              rank: state.vacation_preference_set.weeks.length + 1,
            },
          ]
        : updateRanking(
            state.vacation_preference_set.weeks.filter(
              (week) => week.start_date.toString() !== selectedStartDate
            )
          );

      dispatch({
        type: "UPDATE_VACATION_PREFERENCES_REQUESTED",
        payload: {
          weeks: updatedWeeksPreferences,
          days: state.vacation_preference_set.days,
        },
      });
      upsertVacationPreferences(
        state.vacation_preference_set.preference_set_id,
        updatedWeeksPreferences,
        state.vacation_preference_set.days
      ).then((response) => processUpdateVacationResponse(response));
    }
  };

  const processUpdateVacationResponse = (
    response: Result<VacationPreferenceSet, string>
  ): void => {
    if (response.status == OK) {
      dispatch({
        type: "UPDATE_VACATION_PREFERENCES_SUCCESS",
        payload: {
          preference_set_id: response.value.id,
          weeks: response.value.weeks,
          days: response.value.days,
        },
      });
    } else {
      dispatch({
        type: "UPDATE_VACATION_PREFERENCES_ERROR",
        payload: "Error saving preferences. Please try again",
      });
    }
  };

  useEffect(() => {
    fetchLatestVacationPreferenceSet().then((result) => {
      if (result.status == OK) {
        const preferenceSet = result.value;
        dispatch({
          type: "UPDATE_VACATION_PREFERENCES_SUCCESS",
          payload: {
            preference_set_id: preferenceSet.id,
            weeks: preferenceSet.weeks,
            days: preferenceSet.days,
          },
        });
      }
    });
  }, []);

  const handleDayInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (state?.vacation_preference_set) {
      const updatedDaysPreferences = event.target.checked
        ? [
            ...state.vacation_preference_set.days,
            {
              start_date: event.target.value,
              end_date: event.target.value,
              rank: state.vacation_preference_set.days.length + 1,
            },
          ]
        : updateRanking(
            state.vacation_preference_set.days.filter(
              (day) => day.start_date.toString() !== event.target.value
            )
          );

      dispatch({
        type: "UPDATE_VACATION_PREFERENCES_REQUESTED",
        payload: {
          weeks: state.vacation_preference_set.weeks,
          days: updatedDaysPreferences,
        },
      });
      upsertVacationPreferences(
        state.vacation_preference_set.preference_set_id,
        state.vacation_preference_set.weeks,
        updatedDaysPreferences
      ).then((response) => processUpdateVacationResponse(response));
    }
  };

  const updateRanking = (
    preferences: VacationPreferenceRequest[]
  ): VacationPreferenceRequest[] => {
    return preferences.map((pref, index) => ({
      ...pref,
      rank: index + 1,
    }));
  };

  const alreadySelected = (
    preferences: VacationPreferenceRequest[],
    value: string
  ): boolean => {
    return preferences.some((pref) => pref.start_date === value);
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
            checked={alreadySelected(
              state.vacation_preference_set.days,
              day.date.toString()
            )}
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
            value={[week.start_date, week.end_date].join(":")}
            onChange={(e) => handleWeekInputChange(e)}
            checked={alreadySelected(
              state.vacation_preference_set.weeks,
              week.start_date.toString()
            )}
          />
        </label>
      </div>
    );
  };

  const DisplaySelectedPreferences = (): JSX.Element => {
    return (
      <div>
        <h3>Preferred Vacation</h3>
        <h4>Weeks</h4>
        <ul>
          {state.vacation_preference_set.weeks.map((week) =>
            DisplayPreference(week)
          )}
        </ul>
        <h4>Days</h4>
        <ul>
          {state.vacation_preference_set.days.map((day) =>
            DisplayPreference(day)
          )}
        </ul>
      </div>
    );
  };

  const DisplayPreference = (
    preference: VacationPreferenceRequest
  ): JSX.Element => {
    return (
      <li key={preference.start_date.toString()}>
        {preference.rank + ". " + preference.start_date}
      </li>
    );
  };

  const DisplayErrorMessage = (): JSX.Element => {
    return <p>{state.error_msg}</p>;
  };

  const availQuota: Result<DivisionAvailableVacationQuotaData, string> =
    useDivisionAvailableVacationQuotas();

  const DisplayAvailableQuota = () => {
    return availQuota.status == OK ? (
      <div>
        <h3>Available Vacation Time</h3>
        <h4>Weeks</h4>
        {availQuota.value.weeks.map((week) => VacationWeekDisplay(week))}

        <h4>Days</h4>
        {availQuota.value.days.map((day) => VacationDayDisplay(day))}
      </div>
    ) : (
      <p>availableDivisionQuotaResult.value</p>
    );
  };

  return (
    <div>
      {DisplaySelectedPreferences()}
      {DisplayErrorMessage()}
      {DisplayAvailableQuota()}
    </div>
  );
};

export default VacationPreferenceForm;
