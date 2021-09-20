import { VacationPickRoundData } from "../vacationPickRound";

export interface VacationPickRound {
  roundId: string;
  processId: string;
  employeeId: string;
  rank: number;
  cutoffTime: string;
  intervalType: "week" | "day";
}

export const vacationPickRoundFromData = (
  pickRoundData: VacationPickRoundData
): VacationPickRound => ({
  roundId: pickRoundData.round_id,
  processId: pickRoundData.process_id,
  intervalType: pickRoundData.interval_type,
  employeeId: pickRoundData.employee_id,
  rank: pickRoundData.rank,
  cutoffTime: pickRoundData.cutoff_time,
});
