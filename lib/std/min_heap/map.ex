defmodule Exa.Std.MinHeap.Map do
  @moduledoc """
  A minimum heap implemented using a map.
  The minimum valued key is stored separately.

  If there are multiple keys with the same value,
  their ordering is arbitrary.

  All functions are O(1) except `pop/1` 
  and `delete/2` of the minimum entry, 
  which are both O(n).
  """

  defmodule MHMap do
    alias Exa.Std.MinHeap, as: API

    defstruct kmin: nil,
              map: %{}

    @type t :: %__MODULE__{
            kmin: API.key(),
            map: %{API.key() => API.val()}
          }
  end

  # O(1)
  @doc "Create an empty heap."
  @spec new() :: MHMap.t()
  def new(), do: %MHMap{}

  # --------
  # protocol
  # --------

  defimpl Exa.Std.MinHeap, for: MHMap do
    # O(1)
    def size(%MHMap{map: map}), do: map_size(map)

    # O(1)
    def has_key?(%MHMap{map: map}, k), do: is_map_key(map, k)

    # O(1)
    def get(heap, k, default \\ nil)
    def get(%MHMap{map: map}, k, _default) when is_map_key(map, k), do: map[k]
    def get(_, _k, default), do: default

    # O(1)
    def fetch!(heap, k) do
      case get(heap, k, :empty) do
        :empty -> raise(ArgumentError, message: "Heap missing key '#{k}'")
        v -> v
      end
    end

    # O(1)
    def to_list(%MHMap{map: map}), do: Map.to_list(map)

    # O(n)
    def to_map(%MHMap{map: map}), do: map

    # O(1) for most keys; O(n) for deleting min key
    def delete(%MHMap{map: map} = heap, k) when not is_map_key(map, k), do: heap
    def delete(%MHMap{kmin: kmin} = heap, kmin), do: heap |> pop() |> elem(1)
    def delete(%MHMap{kmin: kmin, map: map}, k), do: %MHMap{kmin: kmin, map: Map.delete(map, k)}

    # O(1)
    def peek(%MHMap{kmin: nil, map: %{}}), do: :empty
    def peek(%MHMap{kmin: kmin, map: map}), do: {kmin, map[kmin]}

    # O(1)

    def push(%MHMap{kmin: nil, map: %{}}, k, v), do: %MHMap{kmin: k, map: %{k => v}}

    def push(%MHMap{kmin: kmin, map: map} = heap, k, v) do
      cond do
        is_map_key(map, k) and v >= map[k] -> heap
        v < map[kmin] -> %MHMap{kmin: k, map: Map.put(map, k, v)}
        true -> %MHMap{kmin: kmin, map: Map.put(map, k, v)}
      end
    end

    # O(n)

    def pop(%MHMap{kmin: nil, map: %{}}), do: :empty

    def pop(%MHMap{kmin: kmin, map: map}) do
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

      {{kmin, vmin}, %MHMap{kmin: new_kmin, map: new_map}}
    end
  end
end
