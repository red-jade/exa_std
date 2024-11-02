defmodule Exa.Std.Histo1DTest do
  use ExUnit.Case

  import Exa.Std.Histo1D

  test "simple" do
    h = new()
    assert_bins(h, [])
    assert :empty = homogeneous(h)

    h = inc(h, 5)
    assert_bins(h, [0, 0, 0, 0, 0, 1])
    assert_mean_median(h, 5.0, 4.5)
    assert {:homo, 5} = homogeneous(h)

    h = h |> inc(1) |> inc(2) |> inc(3) |> inc(4)
    assert_bins(h, [0, 1, 1, 1, 1, 1])
    assert_mean_median(h, 3.0, 2.5)
    assert :not_homo = homogeneous(h)

    h = h |> inc(2) |> inc(3) |> inc(4)
    assert_bins(h, [0, 1, 2, 2, 2, 1])
    assert_mean_median(h, 3.0, 2.5)
    assert :not_homo = homogeneous(h)

    h = h |> inc(3) |> inc(4)
    assert_bins(h, [0, 1, 2, 3, 3, 1])
    assert_mean_median(h, 3.1, 2 + 2 / 3)
    assert :not_homo = homogeneous(h)

    h = h |> inc(4)
    assert_bins(h, [0, 1, 2, 3, 4, 1])
    assert_mean_median(h, 35 / 11, 2 + 2.5 / 3)
    assert :not_homo = homogeneous(h)

    # 0 + 1 + 2 + 3 + 4 + 1 = 11
    11 = total_count(h)

    # 0 + 1*1 + 2*2 + 3*3 + 4*4 + 5*1 = 35
    35 = total_value(h)

    h = h |> dec(3) |> dec(4)
    assert_bins(h, [0, 1, 2, 2, 3, 1])

    # Allow -ve values to evade race conditions
    # assert_raise RuntimeError, "Histogram: cannot decrement 0 count at index 0", fn ->
    #   dec(h, 0)
    # end
  end

  test "roundtrip" do
    a = []
    ^a = a |> new() |> to_list()

    b = [0, 1, 2, 0, 4]
    ^b = b |> new() |> to_list()
  end

  test "change values" do
    [0, 0, 4, 2] =
      [0, 1, 2, 3] |> new() |> add(1) |> sub(3) |> to_list()

    [1, 0, 1, 4] =
      [0, 1, 2, 3] |> new() |> add(2) |> sub(1) |> to_list()

    # Allow -ve values to evade race conditions
    # assert_raise RuntimeError, "Histogram: cannot decrement 0 count at index 1", fn ->
    #   [1, 0] |> new() |> sub(1) |> to_list()
    # end

    assert_raise FunctionClauseError, fn ->
      [1, 0] |> new() |> sub(0) |> to_list()
    end
  end

  test "pdf cdf" do
    h = new([0, 1, 2, 2, 0, 3, 1, 1])

    pdf = pdf(h)
    assert [0.0, 0.1, 0.2, 0.2, 0.0, 0.3, 0.1, 0.1] == pdf
    assert 1.0 == Enum.sum(pdf)

    cdf = cdf(h)
    assert [0.0, 0.1, 0.3, 0.5, 0.5, 0.8, 0.9, 1.0] == cdf

    # all zero means empty
    h0 = new([0, 0, 0, 0, 0])
    assert [] == pdf(h0)
    assert [] == cdf(h0)

    # -ve count
    hneg = new([0, 0, 1, 1]) |> dec(1)
    assert [0.0, -1.0, 1.0, 1.0] == pdf(hneg)
    assert [0.0, -1.0, 0.0, 1.0] == cdf(hneg)

    # zero total count for non-empty 
    hneg = dec(hneg, 2)
    assert_raise ArgumentError, fn -> pdf(hneg) end
    assert_raise ArgumentError, fn -> cdf(hneg) end
  end

  test "crop" do
    # raise RuntimeError, message: "TODO"
  end

  defp assert_mean_median(h, av, md) do
    assert av == mean(h)
    assert md == median(h)
  end

  defp assert_bins(h, bins) do
    len = length(bins)
    assert len == size(h)
    assert bins == to_list(h)
  end
end
