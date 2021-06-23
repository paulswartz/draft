import { Dispatch as ReactDispatch } from "react";

export interface VacationPreferenceSetState {
  preference_set_id: number | null;
  weeks: string[];
  days: string[];
}

export interface State {
  vacation_preference_set?: VacationPreferenceSetState | undefined;
  error_msg?: string | undefined | null;
}

export type Dispatch = ReactDispatch<Action>;

export type Reducer = (state: State, action: Action) => State;

export type Action =
  | UpdatePreferencesAction
  | ErrorSavingPreferencesAction
  | LoadLatestPreferencesSuccessAction;

interface UpdatePreferencesAction {
  type: "UPDATE_VACATION_PREFERENCES";
  payload: {
    weeks: string[];
    days: string[];
    preference_set_id: number | null;
  };
}

interface ErrorSavingPreferencesAction {
  type: "SAVE_PREFERENCES_ERROR";
  payload: string;
}

interface LoadLatestPreferencesSuccessAction {
  type: "LOAD_LATEST_PREFERENCES_SUCCESS";
  payload: {
    weeks: string[];
    days: string[];
    preference_set_id: number | null;
  };
}
