import { Dispatch as ReactDispatch } from "react";
import { VacationPreference } from "./models/vacationPreferenceSet";

export interface VacationPreferenceSetState {
  preference_set_id: number | null;
  weeks: VacationPreference[];
  days: VacationPreference[];
}

export interface State {
  vacation_preference_set: VacationPreferenceSetState;
  error_msg: string | null;
}

export const initialState: State = {
  vacation_preference_set: {
    preference_set_id: null,
    weeks: [],
    days: [],
  },
  error_msg: null,
};

export type Dispatch = ReactDispatch<Action>;

export type Reducer = (state: State, action: Action) => State;

export type Action =
  | UpdatePreferencesRequestedAction
  | UpdatePreferencesSuccessAction
  | UpdatePreferencesErrorAction;

interface UpdatePreferencesRequestedAction {
  type: "UPDATE_VACATION_PREFERENCES_REQUESTED";
  payload: {
    weeks: VacationPreference[];
    days: VacationPreference[];
  };
}

interface UpdatePreferencesSuccessAction {
  type: "UPDATE_VACATION_PREFERENCES_SUCCESS";
  payload: {
    weeks: VacationPreference[];
    days: VacationPreference[];
    preference_set_id: number | null;
  };
}

interface UpdatePreferencesErrorAction {
  type: "UPDATE_VACATION_PREFERENCES_ERROR";
  payload: string;
}