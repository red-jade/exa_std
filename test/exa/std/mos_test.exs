defmodule Exa.Std.MosTest do
  use ExUnit.Case
  import Exa.Std.Mos

  doctest Exa.Std.Mos

  test "simple" do
    mos = new() |> add(:foo, 1) |> add(:foo, 2) |> add(:foo, 1)
    assert 2 == size(mos, :foo)
    assert member?(mos, :foo, 1)
    assert member?(mos, :foo, 2)
    assert not member?(mos, :foo, 9)
    assert MapSet.new([1, 2]) == get(mos, :foo)

    mos = mos |> adds(:bar, [1, 2, 3])
    assert MapSet.new([1, 2, 3]) == get(mos, :bar)

    mos = remove(mos, :bar, 2)
    assert MapSet.new([1, 3]) == get(mos, :bar)

    assert 4 == sizes(mos)
    assert MapSet.new([1, 2, 3]) == union_values(mos)

    assert [:bar, :foo] == Enum.sort(find_keys(mos, 1))
    assert [:foo] == find_keys(mos, 2)
    assert [:bar] == find_keys(mos, 3)

    assert %{:foo => MapSet.new([2]), :bar => MapSet.new([3])} == remove_all(mos, 1)
  end

  test "invert" do
    mos = new() |> adds(:foo, [1, 2]) |> adds(:bar, [1, 3])
    som = invert(mos)

    assert som == %{
             1 => MapSet.new([:foo, :bar]),
             2 => MapSet.new([:foo]),
             3 => MapSet.new([:bar])
           }
  end

  test "involute" do
    mos = new() |> touch(2) |> touch(3) |> adds(1, [1, 3])
    som = involute(mos)
    assert Map.keys(mos) == Map.keys(som)
    assert som == %{1 => MapSet.new([1]), 2 => MapSet.new([]), 3 => MapSet.new([1])}
    assert mos == involute(som)
  end
end
