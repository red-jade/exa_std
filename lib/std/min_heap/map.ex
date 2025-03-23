defmodule Exa.Std.MinHeap.Map do
  @moduledoc """
  A minimum heap implemented using a map.
  The minimum valued key is stored separately.

  If there are multiple keys with the same value,
  their ordering is arbitrary.

  All functions are O(1) except `pop/1` and `delete/2`, which are O(n).
  """

  @behaviour Exa.Std.MinHeap.Api

  @impl true
  def new(:mh_map), do: {:mh_map, {nil, %{}}}

  # O(1)
  @impl true
  def size({:mh_map, {_, map}}), do: map_size(map)

  # O(1)
  @impl true
  def has_key?({:mh_map, {_, map}}, k), do: is_map_key(map, k)

  # O(1)
  @impl true
  def get(heap, k, default \\ nil)
  def get({:mh_map, {_, map}}, k, _default) when is_map_key(map, k), do: map[k]
  def get(_, _k, default), do: default

  # O(n)
  @impl true
  def delete({:mh_map, {_, map}} = heap, k) when not is_map_key(map, k), do: heap
  def delete({:mh_map, {kmin, _map}} = heap, kmin), do: heap |> pop() |> elem(1)
  def delete({:mh_map, {kmin, map}}, k), do: {:mh_map, {kmin, Map.delete(map, k)}}

  # O(1)
  @impl true
  def peek({:mh_map, {nil, %{}}}), do: :empty
  def peek({:mh_map, {kmin, map}}), do: {kmin, map[kmin]}

  # O(1)
  @impl true

  def push({:mh_map, {nil, %{}}}, k, v), do: {:mh_map, {k, %{k => v}}}

  def push({:mh_map, {kmin, map}} = heap, k, v) do
    cond do
      is_map_key(map, k) and v >= map[k] -> heap
      v < map[kmin] -> {:mh_map, {k,    Map.put(map, k, v)}}
      true ->          {:mh_map, {kmin, Map.put(map, k, v)}}
    end
  end

  # O(n)
  @impl true

  def pop({:mh_map, {nil, %{}}}), do: :empty

  def pop({:mh_map, {kmin, map}}) do
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

    {{kmin, vmin}, {:mh_map, {new_kmin, new_map}}}
  end
end
