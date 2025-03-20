defmodule Exa.Std.MinHeap do
  @moduledoc """
  A minimum heap sorted data structure.
  """

  @mod Exa.Std.MinHeap.Ord

  @behaviour Exa.Std.MinHeap.Api

  @impl true
  def new(), do: @mod.new()

  @impl true
  def size(heap), do: @mod.size(heap)

  @impl true
  def has_key?(heap, k), do: @mod.has_key?(heap, k)

  @impl true
  def fetch!(heap, k), do: @mod.fetch!(heap, k)

  @impl true
  def get(heap, k, default \\ nil)
  def get(heap, k, default), do: @mod.get(heap, k, default)

  @impl true
  def delete(heap, k), do: @mod.delete(heap, k)

  @impl true
  def peek(heap), do: @mod.peek(heap)

  @impl true
  def push(heap, k, v), do: @mod.push(heap, k, v)

  @impl true
  def pop(heap), do: @mod.pop(heap)
end
