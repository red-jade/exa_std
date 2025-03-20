defmodule Exa.Std.MinHeap.Ord do
  @moduledoc """
  A minimum heap implemented using an ordered list.
  The minimum value is always the head of the list.

  The list has reversed tuple elements: `{value, key}`
  so the term order is the value order.

  If there are multiple keys with the same value,
  their ordering is arbitrary.

  All functions are O(n) except `push` and `delete`, which are O(1).
  """

  @behaviour Exa.Std.MinHeap.Api

  @impl true
  def new(), do: []

  # O(n)
  @impl true
  def has_key?(ord, key) do
    Enum.find_value(ord, false, fn {_v, k} -> k == key end)
  end

  # O(n)
  @impl true
  def size(ord), do: length(ord)

  # O(n)
  @impl true
  def fetch!(ord, k) do
    case get(ord, k) do
      nil -> raise ArgumentError, message: "Heap missing key '#{k}'"
      v -> v
    end
  end

  # O(n)
  @impl true
  def get(ord, key, default \\ nil) do
    Enum.find_value(ord, default, fn
      {v, ^key} -> v
      _ -> false
    end)
  end

  # O(n)
  @impl true
  def delete(ord, k), do: do_del(ord, k, [])

  defp do_del([{_, k} | t], k, acc), do: Enum.reverse(acc, t)
  defp do_del([vk | t], k, acc), do: do_del(t, k, [vk | acc])
  defp do_del([], _, acc), do: Enum.reverse(acc)

  # O(1)
  @impl true
  def peek([]), do: :empty
  def peek([{v, k} | _]), do: {k, v}

  # O(1)
  @impl true
  def pop([]), do: :empty
  def pop([{v, k} | t]), do: {{k, v}, t}

  # O(n)
  @impl true
  def push([], k, v), do: [{v, k}]
  def push(ord, k, v), do: do_push(ord, k, v, [], false)

  # push is equivalent to 'delete' followed by 'add'
  # combine insert with delete or overwrite previous value
  # must do up to one complete traversal to remove any previous value
  # record if a previous value has been found to truncate recursion

  defp do_push([{u, k}], k, v, acc, false),
    # overwrite last entry matching key
    do: do_push([], k, v, [{min(u, v), k} | acc], true)

  defp do_push([{u, k} | _] = t, k, v, acc, false) when u < v,
    # no-op: update is greater than existing entry for the same key
    do: Enum.reverse(acc, t)

  defp do_push([{_, k} | t], k, v, acc, false),
    # remove previous entry for key and mark as removed
    do: do_push(t, k, v, acc, true)

  defp do_push([{u, _} = uj], k, v, acc, f) when u < v,
    # last entry is less than new value, so add new entry to the end
    do: do_push([], k, v, [{v, k}, uj | acc], f)

  defp do_push([{u, _} = uj | t], k, v, acc, f) when u < v,
    # existing entry is less than new value, so copy and continue scan 
    do: do_push(t, k, v, [uj | acc], f)

  defp do_push([uj | t], k, v, acc, false),
    # first existing value greater than the new value
    # so insert new entry and delete through to the end
    do: do_del(t, k, [uj, {v, k} | acc])

  defp do_push([uj | t], k, v, acc, true),
    # first existing value greater than the new value
    # but existing key has already been deleted
    # so insert new entry and return
    do: Enum.reverse(acc, [{v, k}, uj | t])

  defp do_push([], _, _, acc, _), do: Enum.reverse(acc) 
end
