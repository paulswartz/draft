defmodule Draft.ParsingHelpersTest do
  use ExUnit.Case
  alias Draft.PickSetup.ParsingHelpers

  describe "to_date/1" do
    test "Month less than 10" do
      assert ParsingHelpers.to_date("01/12/2034") == ~D[2034-01-12]
    end

    test "Month greater than 10" do
      assert ParsingHelpers.to_date("11/12/2034") == ~D[2034-11-12]
    end
  end

  describe "to_datetime/2" do
    test "PM time less than 10" do
      parsed_datetime = ParsingHelpers.to_datetime("01/12/2034", "500p")

      assert [01, 12, 2034, 17, 00, 00, "America/New_York"] = [
               parsed_datetime.month,
               parsed_datetime.day,
               parsed_datetime.year,
               parsed_datetime.hour,
               parsed_datetime.minute,
               parsed_datetime.second,
               parsed_datetime.time_zone
             ]
    end

    test "AM time less than 10" do
      parsed_datetime = ParsingHelpers.to_datetime("01/12/2034", "500a")

      assert [01, 12, 2034, 05, 00, 00, "America/New_York"] = [
               parsed_datetime.month,
               parsed_datetime.day,
               parsed_datetime.year,
               parsed_datetime.hour,
               parsed_datetime.minute,
               parsed_datetime.second,
               parsed_datetime.time_zone
             ]
    end

    test "PM time greater than 10" do
      parsed_datetime = ParsingHelpers.to_datetime("01/12/2034", "1100p")

      assert [01, 12, 2034, 23, 00, 00, "America/New_York"] = [
               parsed_datetime.month,
               parsed_datetime.day,
               parsed_datetime.year,
               parsed_datetime.hour,
               parsed_datetime.minute,
               parsed_datetime.second,
               parsed_datetime.time_zone
             ]
    end

    test "AM time greater than 10" do
      parsed_datetime = ParsingHelpers.to_datetime("01/12/2034", "1100a")

      assert [01, 12, 2034, 11, 00, 00, "America/New_York"] = [
               parsed_datetime.month,
               parsed_datetime.day,
               parsed_datetime.year,
               parsed_datetime.hour,
               parsed_datetime.minute,
               parsed_datetime.second,
               parsed_datetime.time_zone
             ]
    end
  end
end
