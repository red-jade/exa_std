defmodule Exa.Std.MinHeapTest do
  use ExUnit.Case

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
    IO.inspect(kvmin)
    IO.inspect(tree)
    assert {1, 10} == kvmin

    {kvmin, tree} = MinHeap.pop(tree)
    IO.inspect(kvmin)
    IO.inspect(tree)
    assert {4, 12} == kvmin

    {kvmin, tree} = MinHeap.pop(tree)
    IO.inspect(kvmin)
    IO.inspect(tree)
    assert {2, 16} == kvmin

    {kvmin, tree} = MinHeap.pop(tree)
    IO.inspect(kvmin)
    IO.inspect(tree)
    assert {5, 43} == kvmin

    {kvmin, emptree} = MinHeap.pop(tree)
    IO.inspect(kvmin)
    IO.inspect(emptree)
    assert {3, 67} == kvmin

    {:empty, ^emptree} = MinHeap.pop(emptree)
  end

  test "simple" do
    for mod <- @impls, do: simple(mod)
  end

  defp simple(mod) do
    IO.inspect(mod)

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
    IO.inspect(heap)
    assert {1, 10} == MinHeap.peek(heap)
    {{1, 10}, heap} = MinHeap.pop(heap)
    assert mod.new() |> MinHeap.add(2, 32) == heap

    assert {2, 32} == MinHeap.peek(heap)
    {min, heap} = MinHeap.pop(heap)
    assert {2, 32} == min
    assert mod.new() == heap

    assert :empty = MinHeap.peek(heap)
  end
end
