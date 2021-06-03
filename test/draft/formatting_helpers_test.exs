defmodule Draft.FormattingHelpersTest do
  use ExUnit.Case
  alias Draft.FormattingHelpers

  describe "to_date_string/1" do
    test "Month less than 10" do
      assert ParsingHelpers.to_date_string(~D[2034-01-12]) == "01/12/2034"
    end

    test "Month greater than 10" do
      assert ParsingHelpers.to_date_string(~D[2034-11-12]) == "11/12/2034"
    end
  end
end
