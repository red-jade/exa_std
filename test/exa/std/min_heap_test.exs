defmodule Exa.Std.MinHeapTest do
  use ExUnit.Case

  alias Exa.Random

  alias Exa.Std.MinHeap

  @impls [
    Exa.Std.MinHeap.Map,
    Exa.Std.MinHeap.Ord,
    Exa.Std.MinHeap.Tree
  ]

  test "tree" do
    tree = Exa.Std.MinHeap.Tree.new()
    assert 0 == MinHeap.size(tree)
    assert nil == MinHeap.get(tree, 99)
    assert_raise ArgumentError, fn -> MinHeap.fetch!(tree, 99) end
    assert :empty == MinHeap.peek(tree)

    tree = MinHeap.add(tree, 1, 10)
    assert 1 == MinHeap.size(tree)
    assert 10 == MinHeap.get(tree, 1)
    assert nil == MinHeap.get(tree, 99)
    assert_raise ArgumentError, fn -> MinHeap.fetch!(tree, 99) end
    assert {1, 10} == MinHeap.peek(tree)

    tree = MinHeap.add(tree, 3, 67)
    assert 2 == MinHeap.size(tree)
    assert 67 == MinHeap.get(tree, 3)
    assert nil == MinHeap.get(tree, 99)
    assert_raise ArgumentError, fn -> MinHeap.fetch!(tree, 99) end
    assert {1, 10} == MinHeap.peek(tree)

    tree = MinHeap.add(tree, 2, 16)
    assert 3 == MinHeap.size(tree)
    assert 16 == MinHeap.get(tree, 2)
    assert nil == MinHeap.get(tree, 99)
    assert_raise ArgumentError, fn -> MinHeap.fetch!(tree, 99) end
    assert {1, 10} == MinHeap.peek(tree)

    tree = tree |> MinHeap.add(4, 12) |> MinHeap.add(5, 43)
    assert 5 == MinHeap.size(tree)
    assert 10 == MinHeap.get(tree, 1)
    assert 67 == MinHeap.get(tree, 3)
    assert nil == MinHeap.get(tree, 99)
    assert_raise ArgumentError, fn -> MinHeap.fetch!(tree, 99) end
    assert {1, 10} == MinHeap.peek(tree)

    {kvmin, tree} = MinHeap.pop(tree)
    assert {1, 10} == kvmin

    {kvmin, tree} = MinHeap.pop(tree)
    assert {4, 12} == kvmin

    {kvmin, tree} = MinHeap.pop(tree)
    assert {2, 16} == kvmin

    {kvmin, tree} = MinHeap.pop(tree)
    assert {5, 43} == kvmin

    {kvmin, emptree} = MinHeap.pop(tree)
    assert {3, 67} == kvmin

    assert :empty == MinHeap.pop(emptree)
  end

  test "simple" do
    for mod <- @impls do 
      infinite(mod)
      simple(mod)
    end
  end

  defp infinite(mod) do
    inf = mod.new() 
    |> MinHeap.add(1, 17) 
    |> MinHeap.add(2) 
    |> MinHeap.add(3, 7) 
    |> pop_all()
    
    assert [{3, 7}, {1, 17}, {2, :inf}] == inf
  end

  defp simple(mod) do
    heap =
      mod.new()
      |> MinHeap.add(1, 43)
      |> MinHeap.add(2, 16)
      |> MinHeap.update(1, 24)
      |> MinHeap.update(2, 32)
      |> MinHeap.update(1, 10)

    assert 2 == MinHeap.size(heap)

    assert 32 = MinHeap.get(heap, 2)
    assert 10 = MinHeap.fetch!(heap, 1)

    assert mod.new() |> MinHeap.add(1, 10) == MinHeap.delete(heap, 2)
    assert mod.new() |> MinHeap.add(2, 32) == MinHeap.delete(heap, 1)

    assert :error == MinHeap.get(heap, 99, :error)
    assert_raise ArgumentError, fn -> MinHeap.fetch!(heap, 99) end

    assert {1, 10} == MinHeap.peek(heap)
    {{1, 10}, heap} = MinHeap.pop(heap)
    assert mod.new() |> MinHeap.add(2, 32) == heap

    assert {2, 32} == MinHeap.peek(heap)
    {min, heap} = MinHeap.pop(heap)
    assert {2, 32} == min
    assert mod.new() == heap

    assert :empty = MinHeap.peek(heap)
  end

  test "random" do
    for mod <- @impls, do: random(100, 1, 1_000, mod)
  end

  # generate a random list of n integers between j and k inclusive
  defp random(n, i, j, mod) do
    rand = Random.generate(n, fn -> Random.uniform_int(i,j) end)
    kvs = Enum.zip(1..n, rand)
    heap = Enum.reduce(kvs, mod.new(), fn {k,v}, heap -> MinHeap.add(heap, k, v) end)
    # not just pure flip sort
    # because repeated values for different keys are allowed in any order
    pops = heap |> pop_all() |> vals()
    vals = kvs |> vals() |> Enum.sort()
    assert vals == pops
  end

  defp pop_all(heap, out \\ []) do
    case MinHeap.pop(heap) do
      :empty -> Enum.reverse(out)
      {kv, new_heap} -> pop_all(new_heap, [kv|out])
    end
  end

  defp vals(kvs), do: Enum.map(kvs, &elem(&1,1) )
end
