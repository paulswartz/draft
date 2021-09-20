import { State, Action, Dispatch, initialState } from "../state";
import { useReducer } from "react";
const reducer = (state: State, action: Action): State => {
  switch (action.type) {
    case "UPDATE_VACATION_PREFERENCES_REQUESTED":
      return {
        ...state,
        vacation_preference_set: {
          preference_set_id: state.vacation_preference_set.preference_set_id,
          preferences: action.payload.preferences,
        },
      };

    case "UPDATE_VACATION_PREFERENCES_SUCCESS":
      return {
        ...state,
        vacation_preference_set: {
          preferences: action.payload.preferences,
          preference_set_id: action.payload.preference_set_id,
        },
      };
    case "UPDATE_VACATION_PREFERENCES_ERROR":
      return {
        ...state,
        error_msg: action.payload,
      };
    default:
      throw new Error();
  }
};

export const useVacationPreferencesReducer = (): [State, Dispatch] => {
  return useReducer(reducer, initialState);
};
