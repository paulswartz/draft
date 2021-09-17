import * as React from "react";
import { fetchVacationPickOverview, OK, Result } from "../api";
import { useEffect, useState } from "react";
import { VacationPickRound } from "../models/vacationPickRound";
import VacationPreferenceForm from "./vacationPreferenceForm";

const VacationPick = (): JSX.Element => {
  const [pickOverviewResult, setPickOverview] = useState<Result<
    VacationPickRound | null,
    string
  > | null>(null);

  useEffect(() => {
    fetchVacationPickOverview().then(setPickOverview);
  }, []);

  const pickOverviewDisplay = (
    overview: VacationPickRound | null
  ): JSX.Element => {
    return overview == null ? (
      <p>No open vacation round.</p>
    ) : (
      <div>
        <p>Badge number: {overview.employeeId}</p>
        <p>Rank in group: {overview.rank}</p>
        <p>Cutoff time: {overview.cutoffTime}</p>
        <VacationPreferenceForm pickOverview={overview} />
      </div>
    );
  };

  return (
    <div>
      {pickOverviewResult == null ? (
        <p>Loading</p>
      ) : pickOverviewResult.status == OK ? (
        <div>{pickOverviewDisplay(pickOverviewResult.value)}</div>
      ) : (
        <p>Error fetching vacation pick data. please try again</p>
      )}
    </div>
  );
};

export default VacationPick;
