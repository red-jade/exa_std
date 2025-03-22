defmodule Exa.Std.MinHeapTest do
  use ExUnit.Case

  alias Exa.Std.MinHeap

  @impls [:mh_map, :mh_ord]

  test "simple" do
    for tag <- @impls, do: simple(tag)
  end

  defp simple(tag) do
    heap =
      MinHeap.new(tag) 
      |> MinHeap.push(1, 43)
      |> MinHeap.push(2, 16)
      |> MinHeap.push(1, 24)
      |> MinHeap.push(2, 32)
      |> MinHeap.push(1, 10)

    assert 2 == MinHeap.size(heap)

    assert 16 = MinHeap.get(heap, 2)
    assert 10 = MinHeap.fetch!(heap, 1)

    assert MinHeap.new(tag) |> MinHeap.push(1, 10) == MinHeap.delete(heap, 2)
    assert MinHeap.new(tag) |> MinHeap.push(2, 16) == MinHeap.delete(heap, 1)

    assert :error == MinHeap.get(heap, 99, :error)
    assert_raise ArgumentError, fn -> MinHeap.fetch!(heap, 99) end

    assert {1, 10} == MinHeap.peek(heap)
    {min, heap} = MinHeap.pop(heap)
    assert {1, 10} == min
    assert MinHeap.new(tag) |> MinHeap.push(2, 16) == heap

    assert {2, 16} == MinHeap.peek(heap)
    {min, heap} = MinHeap.pop(heap)
    assert {2, 16} == min
    assert MinHeap.new(tag) == heap

    assert :empty = MinHeap.peek(heap)
  end
end
