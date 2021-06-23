
import {State, Action, Dispatch} from "../state"
import {useReducer} from "react"
const reducer = (state: State | undefined, action: Action): State | undefined =>  {
    switch (action.type) {
      case 'UPDATE_VACATION_PREFERENCES':
        return  { 
          ...state,
          vacation_preference_set: {weeks: action.payload.weeks,
          days: action.payload.days,
          preference_set_id: action.payload.preference_set_id
          }
      }
      case 'SAVE_PREFERENCES_ERROR':
        return  { 
          ...state,
          error_msg: action.payload
      }
      case "LOAD_LATEST_PREFERENCES_SUCCESS":
        console.log("LOAD")
        console.log(action.payload)
      return {vacation_preference_set: {weeks: action.payload.weeks, days: action.payload.days, preference_set_id: action.payload.preference_set_id}}
      default:
        throw new Error();
    }
  }

  export const useVacationPreferencesReducer = (): [State | undefined, Dispatch] => {
    return useReducer(reducer, undefined) 
  }
