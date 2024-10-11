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

  test "add remove" do
    mos = new() |> adds(:foo, [1]) |> adds(:foo, [2, 3]) |> adds(:bar, [1, 3, 4])

    assert mos == %{
             :foo => MapSet.new([1, 2, 3]),
             :bar => MapSet.new([1, 3, 4])
           }

    mos1 = mos |> removes(:foo, MapSet.new([1, 2]))

    assert mos1 == %{
             :foo => MapSet.new([3]),
             :bar => MapSet.new([1, 3, 4])
           }

    mos2 = mos |> removes(:foo, [2, 3]) |> removes(:bar, 1..4)

    assert mos2 == %{
             :foo => MapSet.new([1]),
             :bar => MapSet.new()
           }
  end

  test "invert" do
    mos = new() |> adds(:foo, [1, 2]) |> adds(:bar, [1, 3])
    assert %{2 => [:bar, :foo]} == index_size(mos)

    som = invert(mos)

    assert som == %{
             1 => MapSet.new([:foo, :bar]),
             2 => MapSet.new([:foo]),
             3 => MapSet.new([:bar])
           }
  end

  test "pick" do
    mos1 = new() |> set(:foo, [1, 2]) 
    {1, mos2} = pick(mos1, :foo)
    assert %{:foo => MapSet.new([2])} == mos2
    {2, mos3} = pick(mos2, :foo)
    assert %{:foo => MapSet.new()} == mos3
    assert :error = pick(mos3, :foo)
  end

  test "merge" do
    mos1 = new() |> adds(:foo, [1, 2]) |> adds(:bar, [4])
    mos2 = new() |> adds(:foo, [1, 3]) |> adds(:baz, [5])
    assert %{1 => [:bar], 2 => [:foo]} == index_size(mos1)

    mkey = merge(mos1, :foo, :bar)

    assert mkey == %{
             :foo => MapSet.new([1, 2, 4])
           }

    mall = merge(mos1, mos2)

    assert mall == %{
             :foo => MapSet.new([1, 2, 3]),
             :bar => MapSet.new([4]),
             :baz => MapSet.new([5])
           }
  end

  test "involute" do
    mos = new() |> touch(2) |> touch(3) |> adds(1, [1, 3])
    assert %{0 => [3, 2], 2 => [1]} == index_size(mos)

    som = involute(mos)
    assert Map.keys(mos) == Map.keys(som)
    assert som == %{1 => MapSet.new([1]), 2 => MapSet.new([]), 3 => MapSet.new([1])}
    assert mos == involute(som)
  end
end
