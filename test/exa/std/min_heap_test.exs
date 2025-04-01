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

    tree = MinHeap.push(tree, 1, 10)
    assert 1 == MinHeap.size(tree)
    assert 10 == MinHeap.get(tree, 1)
    assert nil == MinHeap.get(tree, 99)
    assert_raise ArgumentError, fn -> MinHeap.fetch!(tree, 99) end
    assert {1, 10} == MinHeap.peek(tree)

    tree = MinHeap.push(tree, 3, 67)
    assert 2 == MinHeap.size(tree)
    assert 67 == MinHeap.get(tree, 3)
    assert nil == MinHeap.get(tree, 99)
    assert_raise ArgumentError, fn -> MinHeap.fetch!(tree, 99) end
    assert {1, 10} == MinHeap.peek(tree)

    tree = MinHeap.push(tree, 2, 16)
    assert 3 == MinHeap.size(tree)
    assert 16 == MinHeap.get(tree, 2)
    assert nil == MinHeap.get(tree, 99)
    assert_raise ArgumentError, fn -> MinHeap.fetch!(tree, 99) end
    assert {1, 10} == MinHeap.peek(tree)

    tree = tree |> MinHeap.push(4, 12) |> MinHeap.push(5, 43)
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
    heap =
      mod.new()
      |> MinHeap.push(1, 43)
      |> MinHeap.push(2, 16)
      |> MinHeap.push(1, 24)
      |> MinHeap.push(2, 32)
      |> MinHeap.push(1, 10)

    assert 2 == MinHeap.size(heap)

    assert 16 = MinHeap.get(heap, 2)
    assert 10 = MinHeap.fetch!(heap, 1)

    assert mod.new() |> MinHeap.push(1, 10) == MinHeap.delete(heap, 2)
    assert mod.new() |> MinHeap.push(2, 16) == MinHeap.delete(heap, 1)

    assert :error == MinHeap.get(heap, 99, :error)
    assert_raise ArgumentError, fn -> MinHeap.fetch!(heap, 99) end

    assert {1, 10} == MinHeap.peek(heap)
    {min, heap} = MinHeap.pop(heap)
    assert {1, 10} == min
    assert mod.new() |> MinHeap.push(2, 16) == heap

    assert {2, 16} == MinHeap.peek(heap)
    {min, heap} = MinHeap.pop(heap)
    assert {2, 16} == min
    assert mod.new() == heap

    assert :empty = MinHeap.peek(heap)
  end
end
