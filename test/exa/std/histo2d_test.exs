defmodule Exa.Std.Histo2DTest do
  use ExUnit.Case

  import Exa.Std.Histo2D

  test "empty" do
    h = new()
    assert_hdata(h, 0, {0, 0}, :empty)
  end

  test "rountrip to empty" do
    new()
    |> inc({1, 2})
    |> dec({1, 2})
    |> assert_hdata(0, {0, 0}, :empty)
    |> inc({1, 2})
    |> inc({3, 4})
    |> dec({1, 2})
    |> dec({3, 4})
    |> assert_hdata(0, {0, 0}, :empty)
  end

  test "simple" do
    h = new()

    h = inc(h, {1, 2})
    assert_hdata(h, 1, {1, 2}, {:homo, {1, 2}})

    h = inc(h, {3, 2})
    assert_hdata(h, 2, {3, 2}, :not_homo)

    h = h |> inc({1, 1}) |> inc({2, 1}) |> inc({1, 2})
    assert_hdata(h, 5, {3, 2}, :not_homo, [{{1, 1}, 1}, {{1, 2}, 2}, {{2, 1}, 1}, {{3, 2}, 1}])
  end

  test "delta" do
    new([{1, 2}, {3, 2}, {1, 1}, {2, 1}, {1, 2}])
    |> delta({1, 1}, {1, 0})
    |> delta({2, 1}, {0, 1})
    |> delta({2, 2}, {1, 0})
    |> assert_hdata(5, {3, 2}, :not_homo, [{{1, 2}, 2}, {{2, 1}, 1}, {{3, 2}, 2}])
  end

  test "add sub" do
    new([{1, 2}, {3, 2}, {1, 1}, {2, 1}, {1, 2}])
    |> add_i({1, 1})
    |> add_j({2, 1})
    |> add_i({2, 2})
    |> assert_hdata(5, {3, 2}, :not_homo, [{{1, 2}, 2}, {{2, 1}, 1}, {{3, 2}, 2}])
    |> sub_i({3, 2})
    |> sub_j({2, 2})
    |> sub_i({2, 1})
    |> assert_hdata(5, {3, 2}, :not_homo, [{{1, 1}, 1}, {{1, 2}, 2}, {{2, 1}, 1}, {{3, 2}, 1}])
  end

  test "crop" do
    # raise RuntimeError, message: "TODO"
  end

  defp assert_hdata(h, n, dims, homo, hlist) do
    assert_hdata(h, n, dims, homo)
    assert hlist == to_list(h)
    h
  end

  defp assert_hdata(h, n, dims, homo) do
    assert n == total_count(h)
    assert dims == size(h)
    assert homo == homogeneous(h)
    h
  end
end
