import * as React from "react";
import { fetchVacationPickOverview, OK, Result } from "../api";
import { useEffect, useState } from "react";
import { VacationPickRound } from "../models/vacationPickRound";
import VacationPreferenceForm from "./vacationPreferenceForm";

const VacationPick = (): JSX.Element => {
  const [pickOverviewResult, setPickOverview] = useState<Result<
    VacationPickRound,
    string
  > | null>(null);

  useEffect(() => {
    fetchVacationPickOverview().then((result) => {
      setPickOverview(result);
    });
  }, []);

  return (
    <div>
      {pickOverviewResult == null ? (
        <p>Loading</p>
      ) : pickOverviewResult.status == OK ? (
        <VacationPreferenceForm pickOverview={pickOverviewResult.value} />
      ) : (
        <p>Error fetching vacation pick data. please try again</p>
      )}
    </div>
  );
};

export default VacationPick;
