defmodule Exa.Std.MinHeap do
  @moduledoc """
  A minimum heap sorted data structure.

  There is a common behavior API: `Exa.Std.MinHeap.Api`

  There are two concrete implementations:
  - map `Exa.Std.MinHeap.Map` using map data structure
  - ord `Exa.Std.MinHeap.Ord` using ordered list data structure

  The implementation is chosen in the call to `new/1`,
  then subsequent operations are dispatched to the correct module.
  """

  import Exa.Dispatch, only: [dispatch: 4, dispatch: 3]

  alias Exa.Std.MinHeap.Map
  alias Exa.Std.MinHeap.Ord

  # dispatch map from tag to implementation module
  @disp %{:mh_map => Map, :mh_ord => Ord}

  @behaviour Exa.Std.MinHeap.Api

  @impl true
  def new(tag \\ :mh_map), do: dispatch(@disp, tag, :new)

  @impl true
  def size(heap), do: dispatch(@disp, heap, :size)

  @impl true
  def has_key?(heap, k), do: dispatch(@disp, heap, :has_key?, [k])

  @impl true
  def fetch!(heap, k), do: dispatch(@disp, heap, :fetch!, [k])

  @impl true
  def get(heap, k, default \\ nil)
  def get(heap, k, default), do: dispatch(@disp, heap, :get, [k, default])

  @impl true
  def delete(heap, k), do: dispatch(@disp, heap, :delete, [k])

  @impl true
  def peek(heap), do: dispatch(@disp, heap, :peek)

  @impl true
  def push(heap, k, v), do: dispatch(@disp, heap, :push, [k, v])

  @impl true
  def pop(heap), do: dispatch(@disp, heap, :pop)
end
