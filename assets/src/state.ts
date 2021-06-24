import { Dispatch as ReactDispatch } from "react";

export interface VacationPreferenceSetState {
  preference_set_id: number | null;
  weeks: string[];
  days: string[];
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
