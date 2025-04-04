defmodule Exa.Std.MinHeap.Map do
  @moduledoc """
  A minimum heap implemented using a map.
  The minimum valued key is stored separately.

  If there are multiple keys with the same value,
  their ordering is arbitrary.

  All functions are O(1) except `pop/1`, `to_list/1` 
  and `delete/2` of the minimum entry, 
  which are all O(n).
  """

  defmodule MHMap do
    alias Exa.Std.MinHeap, as: MH

    defstruct kmin: nil,
              map: %{}

    @type t :: %__MODULE__{
            kmin: MH.key(),
            map: MH.kvmap()
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
    def get(%MHMap{map: map}, k, default \\ nil), do: Map.get(map, k, default)

    # O(1)
    def fetch!(heap, k) do
      case get(heap, k, :empty) do
        :empty -> raise(ArgumentError, message: "Heap missing key '#{k}'")
        v -> v
      end
    end

    # O(n)
    def to_list(%MHMap{map: map}), do: Map.to_list(map)

    # O(1)
    def to_map(%MHMap{map: map}), do: map

    # O(1) for most keys; O(n) for deleting min key
    def delete(%MHMap{map: map} = heap, k) when not is_map_key(map, k), do: heap
    def delete(%MHMap{kmin: k} = heap, k), do: heap |> pop() |> elem(1)
    def delete(%MHMap{kmin: kmin, map: map}, k), do: %MHMap{kmin: kmin, map: Map.delete(map, k)}

    # O(1)
    def peek(%MHMap{kmin: nil, map: %{}}), do: :empty
    def peek(%MHMap{kmin: kmin, map: map}), do: {kmin, map[kmin]}

    # O(1)
    def add(%MHMap{kmin: nil, map: %{}}, k, v), do: %MHMap{kmin: k, map: %{k => v}}
    def add(%MHMap{map: map} = heap, k, v) when not is_map_key(map, k), do: put(heap, k, v)
    def add(_heap, k, _v), do: raise(ArgumentError, message: "Heap existing key '#{k}'")

    # O(1)
    def update(%MHMap{map: map} = heap, k, v) when is_map_key(map, k), do: put(heap, k, v)
    def update(_heap, k, _v), do: raise(ArgumentError, message: "Heap missing key '#{k}'")

    # for map implementation, we do have tolerant O(1) 'put' function
    @spec put(MHMap.t(), MH.key(), MH.val()) :: MHMap.t()
    defp put(%MHMap{kmin: kmin, map: map}, k, v),
      do: %MHMap{
        kmin: if(v < map[kmin], do: k, else: kmin),
        map: Map.put(map, k, v)
      }

    # O(n)

    def pop(%MHMap{kmin: nil, map: %{}}), do: :empty

    def pop(%MHMap{kmin: kmin, map: map}) do
      {vmin, new_map} = Map.pop!(map, kmin)

      new_kmin =
        case map_size(new_map) do
          0 -> nil
          _ -> new_map |> Enum.reduce(&kvmin/2) |> elem(0)
        end

      {{kmin, vmin}, %MHMap{kmin: new_kmin, map: new_map}}
    end

    @spec kvmin(MH.kvtup(), MH.kvtup()) :: MH.kvtup()
    defp kvmin({_, v1} = e1, {_, v2}) when v1 < v2, do: e1
    defp kvmin(_e1, e2), do: e2
  end
end
