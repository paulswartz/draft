// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
declare function require(name: string): string;
// tslint:disable-next-line
require("../css/app.scss");

import "phoenix_html";
import * as React from "react";
import VacationPick from "./components/vacationPick";
import ReactDOM from "react-dom";
import { BrowserRouter, Route, Switch } from "react-router-dom";

const App = (): JSX.Element => {
  return (
    <BrowserRouter>
      <Switch>
        <Route
          exact={true}
          path="/admin/spoof/operator"
          component={VacationPick}
        />
      </Switch>
    </BrowserRouter>
  );
};

ReactDOM.render(<App />, document.getElementById("app"));
