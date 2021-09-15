import * as React from "react";
import { DivisionAvailableVacationQuota } from "../models/divisionVacationQuota";
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
  VacationPreference,
  VacationPreferenceSet,
} from "../models/vacationPreferenceSet";
import { VacationPickRound } from "../models/vacationPickRound";

type Props = { pickOverview: VacationPickRound };

const VacationPreferenceForm = (props: Props): JSX.Element => {
  const [state, dispatch] = useVacationPreferencesReducer();
  const { pickOverview } = props;

  const availQuota: Result<DivisionAvailableVacationQuota[], string> =
    useDivisionAvailableVacationQuotas(pickOverview);

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const [selectedStartDate, selectedEndDate] = event.target.value.split(":");
    const updatedWeeksPreferences = event.target.checked
      ? [
          ...state.vacation_preference_set.preferences,
          {
            startDate: selectedStartDate,
            endDate: selectedEndDate,
            rank: state.vacation_preference_set.preferences.length + 1,
          },
        ]
      : updateRanking(
          state.vacation_preference_set.preferences.filter(
            (pref) => pref.startDate.toString() !== selectedStartDate
          )
        );

    dispatch({
      type: "UPDATE_VACATION_PREFERENCES_REQUESTED",
      payload: { preferences: updatedWeeksPreferences },
    });
    upsertVacationPreferences(
      pickOverview.roundId,
      pickOverview.processId,
      state.vacation_preference_set.preference_set_id,
      updatedWeeksPreferences
    ).then((response) => processUpdateVacationResponse(response));
  };

  const processUpdateVacationResponse = (
    response: Result<VacationPreferenceSet, string>
  ): void => {
    if (response.status == OK) {
      dispatch({
        type: "UPDATE_VACATION_PREFERENCES_SUCCESS",
        payload: {
          preference_set_id: response.value.id,
          preferences: response.value.preferences,
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
    fetchLatestVacationPreferenceSet(pickOverview).then((result) => {
      if (result.status == OK) {
        const preferenceSet = result.value;
        dispatch({
          type: "UPDATE_VACATION_PREFERENCES_SUCCESS",
          payload: {
            preference_set_id: preferenceSet.id,
            preferences: preferenceSet.preferences,
          },
        });
      }
    });
  }, []);

  const updateRanking = (
    preferences: VacationPreference[]
  ): VacationPreference[] => {
    return preferences.map((pref, index) => ({
      ...pref,
      rank: index + 1,
    }));
  };

  const alreadySelected = (
    preferences: VacationPreference[],
    value: string
  ): boolean => {
    return preferences.some((pref) => pref.startDate === value);
  };

  const VacationDayDisplay = (
    day: DivisionAvailableVacationQuota
  ): JSX.Element => {
    return (
      <div>
        <label>
          {day.startDate}{" "}
          <input
            type="checkbox"
            value={[day.startDate, day.endDate].join(":")}
            onChange={(e) => handleInputChange(e)}
            checked={alreadySelected(
              state.vacation_preference_set.preferences,
              day.startDate.toString()
            )}
          />
        </label>
      </div>
    );
  };

  const VacationWeekDisplay = (
    week: DivisionAvailableVacationQuota
  ): JSX.Element => {
    return (
      <div>
        <label>
          week of {week.startDate}{" "}
          <input
            type="checkbox"
            value={[week.startDate, week.endDate].join(":")}
            onChange={(e) => handleInputChange(e)}
            checked={alreadySelected(
              state.vacation_preference_set.preferences,
              week.startDate.toString()
            )}
          />
        </label>
      </div>
    );
  };

  const DisplaySelectedPreferences = (): JSX.Element => {
    return (
      <div>
        <h3>Preferred Vacation {pickOverview.intervalType + "s"}</h3>
        <ul>
          {state.vacation_preference_set.preferences.map((pref) =>
            DisplayPreference(pref)
          )}
        </ul>
      </div>
    );
  };

  const DisplayPreference = (preference: VacationPreference): JSX.Element => {
    return (
      <li key={preference.startDate.toString()}>
        {preference.rank + ". " + preference.startDate}
      </li>
    );
  };

  const DisplayErrorMessage = (): JSX.Element => {
    return <p>{state.error_msg}</p>;
  };

  const DisplayAvailableQuota = () => {
    return availQuota.status == OK ? (
      <div>
        <h3>Available Vacation {pickOverview.intervalType + "s"}</h3>
        {pickOverview.intervalType == "week"
          ? availQuota.value.map((week) => VacationWeekDisplay(week))
          : availQuota.value.map((day) => VacationDayDisplay(day))}
      </div>
    ) : (
      <p>{availQuota.value}</p>
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
