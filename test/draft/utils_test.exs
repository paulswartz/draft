defmodule Draft.Utils.Test do
  use ExUnit.Case
  alias Draft.Utils

  describe "compare_date_to_range/3" do
    test "date < start date" do
      assert :before_range ==
               Utils.compare_date_to_range(~D[2021-01-01], ~D[2021-01-02], ~D[2021-01-05])
    end

    test "date == start date" do
      assert :before_range ==
               Utils.compare_date_to_range(~D[2021-01-01], ~D[2021-01-01], ~D[2021-01-05])
    end

    test "start date < date < end date " do
      assert :in_range ==
               Utils.compare_date_to_range(~D[2021-01-02], ~D[2021-01-01], ~D[2021-01-05])
    end

    test "date == end date " do
      assert :in_range ==
               Utils.compare_date_to_range(~D[2021-01-05], ~D[2021-01-01], ~D[2021-01-05])
    end

    test "date > end date " do
      assert :after_range ==
               Utils.compare_date_to_range(~D[2021-01-07], ~D[2021-01-01], ~D[2021-01-05])
    end
  end
end
