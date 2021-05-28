defmodule Draft.ParsingHelpersTest do
  use ExUnit.Case
  alias Draft.ParsingHelpers

  describe "to_int/1" do
    test "valid integer" do
      assert ParsingHelpers.to_int("1234") == 1234
    end

    test "nil" do
      assert ParsingHelpers.to_int(nil) == 0
    end

    test "empty string" do
      assert ParsingHelpers.to_int("") == 0
    end
  end

  describe "to_optional_date/1" do
    test "valid date" do
      assert ParsingHelpers.to_optional_date("01/12/2034") == ~D[2034-01-12]
    end

    test "nil" do
      assert ParsingHelpers.to_optional_date(nil) == nil
    end
  end

  describe "to_date/1" do
    test "Month less than 10" do
      assert ParsingHelpers.to_date("01/12/2034") == ~D[2034-01-12]
    end

    test "Month greater than 10" do
      assert ParsingHelpers.to_date("11/12/2034") == ~D[2034-11-12]
    end
  end

  describe "to_minutes/1" do
    test "Hours only" do
      assert ParsingHelpers.to_minutes("10h00") == 600
    end

    test "Minutes only" do
      assert ParsingHelpers.to_minutes("00h30") == 30
    end

    test "Zero minutes" do
      assert ParsingHelpers.to_minutes("00h00") == 0
    end

    test "Hours and minutes" do
      assert ParsingHelpers.to_minutes("10h30") == 630
    end
  end

  describe "hastus_format_to_utc_datetime/2" do
    test "PM time less than 10" do
      parsed_datetime = ParsingHelpers.hastus_format_to_utc_datetime("01/12/2034", "500p")

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
      parsed_datetime = ParsingHelpers.hastus_format_to_utc_datetime("01/12/2034", "500a")

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
      parsed_datetime = ParsingHelpers.hastus_format_to_utc_datetime("01/12/2034", "1100p")

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
      parsed_datetime = ParsingHelpers.hastus_format_to_utc_datetime("01/12/2034", "1100a")

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

    test "X time (next day))" do
      parsed_datetime = ParsingHelpers.hastus_format_to_utc_datetime("01/12/2034", "330x")

      assert %{
               month: 01,
               day: 13,
               year: 2034,
               hour: 8,
               minute: 30,
               second: 00,
               time_zone: "Etc/UTC"
             } = parsed_datetime
    end
  end
end
