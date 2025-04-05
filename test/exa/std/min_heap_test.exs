defmodule Exa.Std.MinHeapTest do
  use ExUnit.Case

  alias Exa.Random

  alias Exa.Std.MinHeap

  @bench_dir Path.join(["test", "bench"])

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
    kvs = random(100, 1, 1_000)
    for mod <- @impls do 
      pops = add_pop(kvs, mod)
      # not just pure flipped sort
      # because repeated values for different keys are allowed in any order
      assert kvs |> vals() |> Enum.sort() == pops |> vals()
    end
  end

  # generate a random list of n integers between j and k inclusive
  # then index with 1-based keys
  defp random(n, i, j) do
    Enum.zip(1..n, Random.generate(n, fn -> Random.uniform_int(i,j) end))
  end

  defp pop_all(heap, out \\ []) do
    case MinHeap.pop(heap) do
      :empty -> Enum.reverse(out)
      {kv, new_heap} -> pop_all(new_heap, [kv|out])
    end
  end

  defp vals(kvs), do: Enum.map(kvs, &elem(&1,1) )

  # test workflows

  defp add_pop(kvs, mod) do
    kvs 
    |> Enum.reduce(mod.new(), fn {k,v}, heap -> MinHeap.add(heap, k, v) end)
    |> pop_all() 
  end

  # ----------
  # benchmarks
  # ----------

  @tag benchmark: true
  @tag timeout: 100_000
  test "random benchmarks" do
    Benchee.run(
      benchmarks(),
      time: 20,
      save: [path: @bench_dir <> "/min_heap.benchee"],
      load: @bench_dir <> "/min_heap.latest.benchee"
    )
  end

  defp benchmarks() do
    n = 1_000
    kvs = random(n,1, 1_000)
    for mod <- @impls, into: %{} do
      impl = mod |> to_string() |> String.split(".") |> List.last() 
      name = Enum.join(["add_pop", n, impl], "_") |> IO.inspect()
      {name, fn -> add_pop(kvs, mod) end}
    end
  end
end
