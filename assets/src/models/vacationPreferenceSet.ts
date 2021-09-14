import {
  VacationPreferenceData,
  VacationPreferenceSetData,
} from "../vacationPreferenceSet";

export interface VacationPreference {
  startDate: string;
  endDate: string;
  rank: number;
}

export interface VacationPreferenceSet {
  preferences: VacationPreference[];
  id: number | null;
}

export const preferenceSetFromData = (
  preferenceSet: VacationPreferenceSetData
): VacationPreferenceSet => ({
  id: preferenceSet.id,
  preferences: preferenceSet.preferences.map((pref) => ({
    startDate: pref.start_date,
    endDate: pref.end_date,
    rank: pref.rank,
  })),
});

export const preferenceToData = (
  preference: VacationPreference
): VacationPreferenceData => ({
  start_date: preference.startDate,
  end_date: preference.endDate,
  rank: preference.rank,
});
