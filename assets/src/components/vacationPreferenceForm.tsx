import * as React from "react";
import {
  DivisionAvailableVacationQuotaData,
  VacationDayQuotaData,
  VacationWeekQuotaData,
} from "../models/divisionVacationQuotaData";
import useDivisionAvailableVacationQuotas from "../hooks/useDivisionAvailableVacationQuotas";
import { useVacationPreferencesReducer } from "../hooks/useVacationPreferencesReducer";
import {
  fetchVacationPreferenceSet,
  OK,
  Result,
  upsertVacationPreferences,
} from "../api";
import { useEffect } from "react";
import { VacationPreferenceRequest } from "../models/vacationPreferenceSet";

const VacationPreferenceForm = (): JSX.Element => {
  const [state, dispatch] = useVacationPreferencesReducer();

  const handleWeekInputChange = (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    const updatedWeekPreferences = event.target.checked
      ? [...state.vacation_preference_set.weeks, event.target.value]
      : state.vacation_preference_set.weeks.filter(
          (week) => week !== event.target.value
        );

    const rankedPreferences = simpleVacationRanking(
      updatedWeekPreferences,
      state.vacation_preference_set.days
    );

    dispatch({
      type: "UPDATE_VACATION_PREFERENCES_REQUESTED",
      payload: {
        weeks: updatedWeekPreferences,
        days: state.vacation_preference_set.days,
      },
    });
    upsertVacationPreferences(
      state.vacation_preference_set.preference_set_id,
      rankedPreferences.ranked_weeks,
      rankedPreferences.ranked_days
    ).then((response) => {
      if (response.status == OK) {
        dispatch({
          type: "UPDATE_VACATION_PREFERENCES_SUCCESS",
          payload: {
            preference_set_id: response.value.id,
            weeks: response.value.weeks.map((pref) =>
              pref.start_date.toString()
            ),
            days: response.value.days.map((pref) => pref.start_date.toString()),
          },
        });
      } else {
        dispatch({
          type: "UPDATE_VACATION_PREFERENCES_ERROR",
          payload: "Error saving preferences. Please try again",
        });
      }
    });
  };

  const simpleVacationRanking = (
    weeks: string[],
    days: string[]
  ): {
    ranked_weeks: VacationPreferenceRequest[];
    ranked_days: VacationPreferenceRequest[];
  } => {
    const ranked_weeks = weeks.map((pref, index) => ({
      start_date: pref,
      rank: index + 1,
    }));
    const ranked_days = days.map((pref, index) => ({
      start_date: pref,
      rank: index + 1,
    }));

    return { ranked_weeks: ranked_weeks, ranked_days: ranked_days };
  };

  useEffect(() => {
    fetchVacationPreferenceSet().then((result) => {
      if (result.status == OK) {
        const preferenceSet = result.value;
        dispatch({
          type: "LOAD_LATEST_PREFERENCES_SUCCESS",
          payload: {
            preference_set_id: preferenceSet.id,
            weeks: preferenceSet.weeks.map((pref) =>
              pref.start_date.toString()
            ),
            days: preferenceSet.days.map((pref) => pref.start_date.toString()),
          },
        });
      }
    });
  }, []);

  const handleDayInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (state?.vacation_preference_set) {
      const updatedDaysPreferences = event.target.checked
        ? [...state.vacation_preference_set.days, event.target.value]
        : state.vacation_preference_set.days.filter(
            (day) => day !== event.target.value
          );
      const rankedPreferences = simpleVacationRanking(
        state.vacation_preference_set.weeks,
        updatedDaysPreferences
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
        rankedPreferences.ranked_weeks,
        rankedPreferences.ranked_days
      ).then((response) => {
        if (response.status == OK) {
          dispatch({
            type: "UPDATE_VACATION_PREFERENCES_SUCCESS",
            payload: {
              preference_set_id: response.value.id,
              weeks: response.value.weeks.map((pref) =>
                pref.start_date.toString()
              ),
              days: response.value.days.map((pref) =>
                pref.start_date.toString()
              ),
            },
          });
        } else {
          dispatch({
            type: "UPDATE_VACATION_PREFERENCES_ERROR",
            payload: "Error saving preferences. Please try again",
          });
        }
      });
    }
  };

  const alreadySelectedWeek = (value: string): boolean => {
    return state.vacation_preference_set.weeks.includes(value);
  };

  const alreadySelectedDay = (value: string): boolean => {
    return state.vacation_preference_set.days.includes(value);
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
    return (
      <div>
        <h3>Preferred Vacation</h3>
        <h4>Weeks</h4>
        <ul>
          {state.vacation_preference_set.weeks.map((week) => (
            <li key={week.toString()}>{week}</li>
          ))}
        </ul>
        <h4>Days</h4>
        <ul>
          {state.vacation_preference_set.days.map((day) => (
            <li key={day.toString()}>{day}</li>
          ))}
        </ul>
      </div>
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
      {DisplayErrorMessage()}
      {DisplaySelectedPreferences()}
      {DisplayAvailableQuota()}
    </div>
  );
};

export default VacationPreferenceForm;
