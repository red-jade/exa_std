defmodule Exa.Std.MinHeap.Map do
  @moduledoc """
  A minimum heap implemented using a map.
  The minimum valued key is stored separately.

  If there are multiple keys with the same value,
  their ordering is arbitrary.

  All functions are O(1) except `pop` and `delete`, which are O(n).
  """

  @behaviour Exa.Std.MinHeap.Api

  @impl true
  def new(), do: {nil, %{}}

  # O(1)
  @impl true
  def size({_, map}), do: map_size(map)

  # O(1)
  @impl true
  def has_key?({_, map}, k), do: is_map_key(map, k)

  # O(1)
  @impl true
  def fetch!({_, map}, k) when is_map_key(map, k), do: map[k]
  def fetch!(_heap, k), do: raise(ArgumentError, message: "Heap missing key '#{k}'")

  # O(1)
  @impl true
  def get(heap, k, default \\ nil)
  def get({_, map}, k, _default) when is_map_key(map, k), do: map[k]
  def get(_, _k, default), do: default

  # O(n)
  @impl true
  def delete({_, map} = heap, k) when not is_map_key(map, k), do: heap
  def delete({kmin, _map} = heap, kmin), do: heap |> pop() |> elem(1)
  def delete({kmin, map}, k), do: {kmin, Map.delete(map, k)}

  # O(1)
  @impl true
  def peek({nil, %{}}), do: :empty
  def peek({kmin, map}), do: {kmin, map[kmin]}

  # O(1)
  @impl true

  def push({nil, %{}}, k, v), do: {k, %{k => v}}

  def push({kmin, map} = heap, k, v) do
    cond do
      is_map_key(map, k) and v >= map[k] -> heap
      v < map[kmin] -> {k, Map.put(map, k, v)}
      true -> {kmin, Map.put(map, k, v)}
    end
  end

  # O(n)
  @impl true

  def pop({nil, %{}}), do: :empty

  def pop({kmin, map}) do
    {vmin, new_map} = Map.pop!(map, kmin)

    new_kmin =
      case map_size(new_map) do
        0 ->
          nil

        _ ->
          new_map
          |> Enum.reduce(fn {_, v} = kv, {_, vmin} = acc ->
            if v < vmin, do: kv, else: acc
          end)
          |> elem(0)
      end

    {{kmin, vmin}, {new_kmin, new_map}}
  end
end
