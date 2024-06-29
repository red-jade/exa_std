defmodule Exa.Std.RleTest do
  use ExUnit.Case
  import Exa.Std.Rle

  doctest Exa.Std.Rle

  test "simple" do
    # rle is just the original list
    roundtrip([], [])
    roundtrip([1], [1])
    roundtrip([1, 2], [1, 2])
    roundtrip([1, 1], [1, 1])
    roundtrip([1, 2, 3], [1, 2, 3])
    # there are some repeated values
    roundtrip([1, 1, 1], [1, {:rle, 1, 2}])
    roundtrip([1, 1, 1, 1], [1, {:rle, 1, 3}])
    roundtrip([1, 1, 2, 2, 3], [1, 1, {:rle, 2, 2}, 3])
  end

  test "min max sum" do
    rle = new([1, 1, 2, 2, 3])
    assert 1 = minimum(rle)
    assert 3 = maximum(rle)
    assert 9 = sum(rle)

    rle = new([1.1, 0.9, 2.1, 1.9, 3.5])
    assert 0.9 = minimum(rle)
    assert 3.5 = maximum(rle)
    assert 9.5 = sum(rle)
  end

  test "at" do
    rle = new([1, 1, 2, 2, 3])
    assert 1 = at(rle, 0)
    assert 1 = at(rle, 1)
    assert 2 = at(rle, 2)
    assert 2 = at(rle, 3)
    assert 3 = at(rle, 4)

    assert_raise ArgumentError, fn -> at(rle, 5) end
  end

  test "take" do
    assert {[], []} = take([], 2)

    list = [1, 1, 2, 2, 3]
    rle = new(list)
    assert {[1], [1, {:rle, 2, 2}, 3]} = take(rle, 1)
    assert {[1, 1], [2, 2, 3]} = take(rle, 2)
    assert {[1, 1, 2], [2, 3]} = take(rle, 3)
    assert {[1, 1, 2, 2], [3]} = take(rle, 4)

    assert {^list, []} = take(rle, 5)
    assert {^list, []} = take(rle, 6)
    assert {^list, []} = take(rle, 99)
  end

  defp roundtrip(list, expect) do
    rle = new(list)
    assert size(rle) == length(list)
    assert ^expect = rle
    hd_tl(list, expect)
    assert ^list = to_list(expect)
  end

  defp hd_tl([], []), do: :ok
  defp hd_tl([h | t], [h | _] = rle), do: hd_tl(t, next(rle))
end
