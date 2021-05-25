defmodule Draft.ParsingHelpersTest do
  use ExUnit.Case
  alias Draft.PickDataSetup.ParsingHelpers

  describe "to_date/1" do
    test "Month less than 10" do
      assert ParsingHelpers.to_date("01/12/2034") == ~D[2034-01-12]
    end

    test "Month greater than 10" do
      assert ParsingHelpers.to_date("11/12/2034") == ~D[2034-11-12]
    end
  end

  describe "to_utc_datetime/2" do
    test "PM time less than 10" do
      parsed_datetime = ParsingHelpers.to_utc_datetime("01/12/2034", "500p")

      assert %{
               month: 01,
               day: 12,
               year: 2034,
               hour: 22,
               minute: 00,
               second: 00,
               time_zone: "Etc/UTC"
             } = parsed_datetime
    end

    test "AM time less than 10" do
      parsed_datetime = ParsingHelpers.to_utc_datetime("01/12/2034", "500a")

      assert %{
               month: 01,
               day: 12,
               year: 2034,
               hour: 10,
               minute: 00,
               second: 00,
               time_zone: "Etc/UTC"
             } = parsed_datetime
    end

    test "PM time greater than 10" do
      parsed_datetime = ParsingHelpers.to_utc_datetime("01/12/2034", "1100p")

      assert %{
               month: 01,
               day: 13,
               year: 2034,
               hour: 4,
               minute: 00,
               second: 00,
               time_zone: "Etc/UTC"
             } = parsed_datetime
    end

    test "AM time greater than 10" do
      parsed_datetime = ParsingHelpers.to_utc_datetime("01/12/2034", "1100a")

      assert %{
               month: 01,
               day: 12,
               year: 2034,
               hour: 16,
               minute: 00,
               second: 00,
               time_zone: "Etc/UTC"
             } = parsed_datetime
    end
  end
end
