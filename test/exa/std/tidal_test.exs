defmodule Exa.Std.TidalTest do
  use ExUnit.Case

  import Exa.Std.Tidal

  @empty_range 0..1//-1

  test "empty" do
    t = new()
    assert_tidal(t, 0, 0, [])
    assert not complete?(t)
    assert {@empty_range, []} == to_range_list(t)

    assert_raise FunctionClauseError, fn -> put(t, 0) end
    assert_raise FunctionClauseError, fn -> put(t, -1) end
  end

  test "simple" do
    t = new() |> put(1) |> put(2) |> put(3)
    assert_tidal(t, 3, 3, [1, 2, 3])
    assert complete?(t)
    assert {1..3, []} == to_range_list(t)

    assert {:duplicate, 1, ^t} = put(t, 1)
  end

  test "simple advance" do
    t0 = new()
    {t1, 1..1} = advance(t0, 1)
    {t2, 2..2} = advance(t1, 2)
    {t3, 3..3} = advance(t2, 3)

    assert_tidal(t3, 3, 3, [1, 2, 3])
    assert complete?(t3)
    assert {1..3, []} == to_range_list(t3)

    assert {:duplicate, 1, ^t3} = put(t3, 1)
    assert {:duplicate, 1, ^t3, @empty_range} = advance(t3, 1)
  end

  test "skip" do
    t = new() |> put(2) |> put(3)
    assert_tidal(t, 0, 3, [2, 3])
    assert not complete?(t)
    assert {@empty_range, [2, 3]} == to_range_list(t)
  end

  test "skip advance" do
    t0 = new()
    {t2, @empty_range} = advance(t0, 2)
    {t3, @empty_range} = advance(t2, 3)
    assert_tidal(t3, 0, 3, [2, 3])
    assert not complete?(t3)
    assert {@empty_range, [2, 3]} == to_range_list(t3)
  end

  test "jump" do
    t = new() |> put(1) |> put(3)
    assert_tidal(t, 1, 3, [1, 3])
    assert not complete?(t)
    assert {1..1, [3]} == to_range_list(t)
  end

  test "jump advance" do
    t0 = new()
    {t1, 1..1} = advance(t0, 1)
    {t3, @empty_range} = advance(t1, 3)
    assert_tidal(t3, 1, 3, [1, 3])
    assert not complete?(t3)
    assert {1..1, [3]} == to_range_list(t3)
  end

  test "rollup" do
    t = new() |> put(1) |> put(3) |> put(4)
    assert_tidal(t, 1, 4, [1, 3, 4])
    assert not complete?(t)
    assert {1..1, [3, 4]} == to_range_list(t)

    # make contiguous
    s = put(t, 2)
    assert_tidal(s, 4, 4, [1, 2, 3, 4])
    assert complete?(s)
    assert {1..4, []} == to_range_list(s)

    # create two gaps
    u = put(t, 6)
    assert_tidal(u, 1, 6, [1, 3, 4, 6])
    assert not complete?(u)
    assert {1..1, [3, 4, 6]} == to_range_list(u)

    # fill first gap
    v = put(u, 2)
    assert_tidal(v, 4, 6, [1, 2, 3, 4, 6])
    assert not complete?(v)
    assert {1..4, [6]} == to_range_list(v)

    # fill second gap
    w = put(u, 5)
    assert_tidal(w, 1, 6, [1, 3, 4, 5, 6])
    assert not complete?(w)
    assert {1..1, [3, 4, 5, 6]} == to_range_list(w)

    # make complete
    x = put(w, 2)
    assert_tidal(x, 6, 6, [1, 2, 3, 4, 5, 6])
    assert complete?(x)
    assert {1..6, []} == to_range_list(x)
  end

  test "rollup advance" do
    t = new() |> put(1) |> put(3) |> put(4)
    assert_tidal(t, 1, 4, [1, 3, 4])
    assert not complete?(t)
    assert {1..1, [3, 4]} == to_range_list(t)

    # make contiguous
    {s, 2..4} = advance(t, 2)
    assert_tidal(s, 4, 4, [1, 2, 3, 4])

    # create two gaps
    {u, @empty_range} = advance(t, 6)
    assert_tidal(u, 1, 6, [1, 3, 4, 6])

    # fill first gap
    {v, 2..4} = advance(u, 2)
    assert_tidal(v, 4, 6, [1, 2, 3, 4, 6])

    # fill second gap - no advance
    {w, @empty_range} = advance(u, 5)
    assert_tidal(w, 1, 6, [1, 3, 4, 5, 6])

    # make complete
    {x, 2..6} = advance(w, 2)
    assert_tidal(x, 6, 6, [1, 2, 3, 4, 5, 6])
  end

  test "roundtrip" do
    assert_roundtrip([1, 2, 3])
    assert_roundtrip([2, 3])
    assert_roundtrip([2, 3, 5])
    assert_roundtrip([1, 2, 4, 5, 7])
    assert_roundtrip([1, 2, 3, 16, 97])

    assert_roundtrip(Enum.reverse([1, 2, 3]))
    assert_roundtrip(Enum.reverse([2, 3]))
    assert_roundtrip(Enum.reverse([2, 3, 5]))
    assert_roundtrip(Enum.reverse([1, 2, 4, 5, 7]))
    assert_roundtrip(Enum.reverse([1, 2, 3, 16, 97]))
  end

  defp assert_roundtrip(vals) do
    assert Enum.sort(vals) == vals |> from_list() |> to_list()
  end

  defp assert_tidal(t, lwm, hwm, vals) do
    # IO.inspect(t)
    # IO.inspect(vals)
    assert_tidal(t)
    assert lwm == lwm(t)
    assert hwm == hwm(t)
    len = length(vals)
    assert len == size(t)
    assert vals == to_list(t)
  end

  defp assert_tidal({:tidal, lwm, hwm, ids} = t) do
    vals = to_list(t)
    assert lwm >= 0
    assert hwm >= lwm
    assert hwm != lwm + 1
    assert not MapSet.member?(ids, lwm)

    if hwm == 0 do
      assert lwm == 0
      assert MapSet.size(ids) == 0
    end

    if hwm > lwm do
      assert MapSet.member?(ids, hwm)
      assert not MapSet.member?(ids, lwm + 1)
      assert Enum.reduce(ids, true, fn i, b -> b and i > lwm + 1 and i <= hwm end)
      assert Enum.max(vals) == hwm
      n = MapSet.size(ids)
      assert 1 <= n and n <= hwm - lwm - 1
    end
  end
end
