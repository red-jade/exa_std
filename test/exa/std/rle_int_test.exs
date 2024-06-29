defmodule Exa.Std.RleIntTest do
  use ExUnit.Case
  import Exa.Std.RleInt

  @small [1, -2, 4, 4, -3, -2, 0, 3, 2]

  @jump [1, 2, 19, 20, 12, 0, -5, -20, -13, -1]

  doctest Exa.Std.RleInt

  test "simple" do
    empty = new([], :auto, 8)
    IO.inspect(empty, label: "empty")
    assert [] == to_list(empty)
    assert_raise ArgumentError, fn -> at(empty, 0) end
    IO.puts("\n")

    r1_10 = Range.to_list(1..10)
    ten = new(r1_10, :auto, 8)
    IO.inspect(ten, label: "ten")
    assert_content(r1_10, ten)
    assert_sum_min_max(55, 1, 10, ten)
    assert {[1, 2, 3], [4 | _]} = take(ten, 3)
    IO.puts("\n")

    small = new(@small, :auto, 8)
    IO.inspect(small, label: "small")
    assert_content(@small, small)
    assert_sum_min_max(7, -3, 4, small)
    assert {[1, -2, 4], [4 | _]} = take(small, 3)
    IO.puts("\n")

    jump = new(@jump, 4, 8)
    IO.inspect(jump, label: "jump")
    assert_content(@jump, jump)
    assert_sum_min_max(15, -20, 20, jump)
    assert {[1, 2, 19], [20 | _]} = take(jump, 3)

    assert {@jump, []} = take(jump, 99)
  end

  test "zip dot zip_reduce" do
    r1_5 = new([1, 2, 3, 4, 5], 2)

    assert [2, 4, 6, 8, 10] == map(r1_5, fn i -> 2 * i end) |> to_list()
    assert [2, 4, 6, 8, 10] == zip(r1_5, r1_5, fn a, b -> a + b end) |> to_list()
    assert 30 == zip_reduce(r1_5, r1_5, 0, fn a, b, s -> s + a + b end)
    assert 55 == dot(r1_5, r1_5)
  end

  test "sin" do
    waves = sin(500, 20, 16)

    sin4 = new(waves, 4, 8)
    assert_content(waves, sin4)
    IO.puts("\n")

    sinauto = new(waves, :auto, 8)
    assert_content(waves, sinauto)
  end

  defp assert_content(expect, irle) do
    n = length(expect)
    assert n == size(irle)
    assert expect == to_list(irle)

    Enum.each(0..(n - 1), fn i ->
      assert Enum.at(expect, i) == at(irle, i)
    end)

    Enum.reduce(0..(n - 1), {expect, irle}, fn _i, {[eh | et], [rh | _] = irle} ->
      assert eh == rh
      {et, next(irle)}
    end)

    compres = compression(irle)
    IO.puts("compression: #{compres}%")
  end

  defp sin(n, cycle, scale) do
    Enum.map(0..(n - 1), fn i ->
      trunc(scale * Exa.Math.sind(360.0 * i / cycle))
    end)
  end

  defp assert_sum_min_max(sum, min, max, irle) do
    assert sum == sum(irle)
    assert min == minimum(irle)
    assert max == maximum(irle)
  end
end
