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
    inf =
      mod.new()
      |> MinHeap.add(1, 17)
      |> MinHeap.add(2)
      |> MinHeap.add(3, 7)
      |> pops()

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
    # ensure add all then pop all sorts the values
    kvs = random(100, 1, 1_000)

    for mod <- @impls do
      pops = add_pop(mod, kvs)
      # not just pure flipped sort of value-key pairs
      # because repeated values for different keys are allowed in any order
      assert kvs |> vals() |> Enum.sort() == pops |> vals()
    end
  end

  # generate a random list of n integers between j and k inclusive
  # then index with 1-based keys
  defp random(n, i, j) do
    Enum.zip(1..n, Random.generate(n, fn -> Random.uniform_int(i, j) end))
  end

  # pop a number of entries from the heap
  # if m is -ve (default) all entries are popped

  defp pops(heap, m \\ -1, out \\ [])

  defp pops(_heap, 0, out), do: Enum.reverse(out)

  defp pops(heap, m, out) do
    case MinHeap.pop(heap) do
      :empty -> Enum.reverse(out)
      {kv, new_heap} -> pops(new_heap, m - 1, [kv | out])
    end
  end

  # get all values from a kv list
  defp vals(kvs), do: Enum.map(kvs, &elem(&1, 1))

  # --------------
  # test workflows
  # --------------

  defp add_pop(mod, kvs) do
    # add all, pop all
    heap = mod.new()
    heap = Enum.reduce(kvs, heap, fn {k, v}, heap -> MinHeap.add(heap, k, v) end)
    pops(heap)
  end

  # add all, update some fraction, pop some fraction
  # typically m << length(kvs)
  defp add_upd_pop(mod, kvs, m) do
    heap = mod.new()
    heap = Enum.reduce(kvs, heap, fn {k, v}, heap -> MinHeap.add(heap, k, v) end)
    heap = Enum.reduce(1..m, heap, fn i, heap -> MinHeap.update(heap, i, i) end)
    pops(heap, m)
  end

  # ----------
  # benchmarks
  # ----------

  @tag benchmark: true
  @tag timeout: 200_000
  test "random benchmarks" do
    Benchee.run(
      benchmarks(),
      time: 20,
      save: [path: @bench_dir <> "/min_heap.benchee"],
      load: @bench_dir <> "/min_heap.latest.benchee"
    )
  end

  defp benchmarks() do
    # total number of kv pairs
    n = 1_000
    # number of updates and pops 20%
    m = div(n, 5)
    # random values for add
    kvs = random(n, 1, 1_000)

    benchs =
      Enum.reduce(@impls, %{}, fn mod, benchs ->
        Map.put(benchs, test_name("add_pop", n, mod), fn -> add_pop(mod, kvs) end)
      end)

    Enum.reduce(@impls, benchs, fn mod, benchs ->
      Map.put(benchs, test_name("add_upd_pop", n, mod), fn -> add_upd_pop(mod, kvs, m) end)
    end)
  end

  defp test_name(name, n, mod) do
    impl = mod |> to_string() |> String.split(".") |> List.last()
    Enum.join([name, n, impl], "_")
  end
end
