defmodule Exa.Std.Histo3DTest do
  use ExUnit.Case

  import Exa.Std.Histo3D

  test "empty" do
    h = new()
    assert_hdata(h, 0, {0, 0, 0}, :empty)
  end

  test "rountrip to empty" do
    new()
    |> inc({1, 2, 3})
    |> dec({1, 2, 3})
    |> assert_hdata(0, {0, 0, 0}, :empty)
    |> inc({1, 2, 5})
    |> inc({3, 4, 7})
    |> dec({1, 2, 5})
    |> dec({3, 4, 7})
    |> assert_hdata(0, {0, 0, 0}, :empty)
  end

  test "simple" do
    h = new()

    h = inc(h, {1, 2, 3})
    assert_hdata(h, 1, {1, 2, 3}, {:homo, {1, 2, 3}})

    h = inc(h, {3, 2, 5})
    assert_hdata(h, 2, {3, 2, 5}, :not_homo)

    h = h |> inc({1, 1, 1}) |> inc({2, 1, 2}) |> inc({1, 2, 3})

    assert_hdata(h, 5, {3, 2, 5}, :not_homo, [
      {{1, 1, 1}, 1},
      {{1, 2, 3}, 2},
      {{2, 1, 2}, 1},
      {{3, 2, 5}, 1}
    ])
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
