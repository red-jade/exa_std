defmodule Exa.Std.MinHeap.Ord do
  @moduledoc """
  A minimum heap implemented using an ordered list.
  The minimum value is always the head of the list.

  The list has reversed tuple elements: `{value, key}`
  so the term order is the value order.

  If there are multiple keys with the same value,
  their order will be by key (ascending).

  All functions are O(n) except `peek/1` and `pop/1`, 
  which are both O(1).
  """
  alias Exa.Std.MinHeap, as: MH

  defmodule MHOrd do
    alias Exa.Std.MinHeap, as: MH

    @type vklist() :: [MH.vktup()]

    defstruct ord: []

    @type t :: %__MODULE__{
            ord: vklist()
          }
  end

  # O(1)
  @doc "Create an empty heap."
  @spec new() :: MHOrd.t()
  def new(), do: %MHOrd{}

  # --------
  # protocol
  # --------

  defimpl Exa.Std.MinHeap, for: MHOrd do
    alias Exa.Std.MinHeap, as: MH

    # O(n)
    def has_key?(%MHOrd{ord: ord}, key), do: do_has?(ord, key)

    @spec do_has?(MHOrd.vklist(), MH.key()) :: bool()
    defp do_has?([], _), do: false
    defp do_has?([{_, k} | _], k), do: true
    defp do_has?([_ | t], k), do: do_has?(t, k)

    # O(n)
    def size(%MHOrd{ord: ord}), do: length(ord)

    # O(n)
    def get(%MHOrd{ord: ord}, key, default \\ nil), do: do_get(ord, key, default)

    @spec do_get(MHOrd.vklist(), MH.key(), d) :: d | MH.val() when d: var
    defp do_get([], _, default), do: default
    defp do_get([{v, k} | _], k, _), do: v
    defp do_get([_ | t], k, default), do: do_get(t, k, default)

    # O(n)
    def fetch!(heap, k) do
      case get(heap, k, :empty) do
        :empty -> raise(ArgumentError, message: "Heap missing key '#{k}'")
        v -> v
      end
    end

    # O(n)
    def to_list(%MHOrd{ord: ord}),
      do: Enum.map(ord, fn {v, k} -> {k, v} end)

    # O(n)
    def to_map(%MHOrd{ord: ord}),
      do: Enum.reduce(ord, %{}, fn {v, k}, m -> Map.put(m, k, v) end)

    # O(n)
    # no error for missing key
    def delete(%MHOrd{ord: ord}, k),
      do: %MHOrd{ord: ord |> do_del(k, []) |> elem(1)}

    @spec do_del(MHOrd.vklist(), MH.key(), MHOrd.vklist()) ::
            {:found | :not_found, MHOrd.vklist()}
    defp do_del([], _, acc), do: {:not_found, Enum.reverse(acc)}
    defp do_del([{_, k} | t], k, acc), do: {:found, Enum.reverse(acc, t)}
    defp do_del([vk | t], k, acc), do: do_del(t, k, [vk | acc])

    # O(1)
    def peek(%MHOrd{ord: []}), do: :empty
    def peek(%MHOrd{ord: [{v, k} | _]}), do: {k, v}

    # O(1)
    def pop(%MHOrd{ord: []}), do: :empty
    def pop(%MHOrd{ord: [{v, k} | t]}), do: {{k, v}, %MHOrd{ord: t}}

    # O(n)
    # delete and add - slow but easy
    def update(%MHOrd{ord: ord}, k, v) do
      case do_del(ord, k, []) do
        {:found, new_ord} -> %MHOrd{ord: do_add(new_ord, k, v, [])}
        {:not_found, _ord} -> raise(ArgumentError, message: "Heap missing key '#{k}'")
      end
    end

    # O(n)
    def add(%MHOrd{ord: []}, k, v), do: %MHOrd{ord: [{v, k}]}
    def add(%MHOrd{ord: ord}, k, v), do: %MHOrd{ord: do_add(ord, k, v, [])}

    # note - does not raise for old key after new insertion point
    @spec do_add(MHOrd.vklist(), MH.key(), MH.val(), MHOrd.vklist()) :: MHOrd.vklist()
    defp do_add([{_, k} | _], k, _, _acc),
      do: raise(ArgumentError, message: "Heap existing key '#{k}'")

    defp do_add([], k, v, acc), do: Enum.reverse([{v, k} | acc])
    defp do_add([{u, _} | _] = t, k, v, acc) when v < u, do: Enum.reverse([{v, k} | acc], t)
    defp do_add([uj | t], k, v, acc), do: do_add(t, k, v, [uj | acc])
  end
end
