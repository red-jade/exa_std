defmodule Exa.Std.Mos do
  @moduledoc """
  Map of Sets (MoS).

  The presence of the empty set is significant.
  There is a difference between a missing key
  and a key with the empty set as a value.
  There is no policy of removal-on-empty.

  An MoS is a Map, so all `Map` and `Exa.Map` functions can be applied.

  The general policy is not to include a function in MoS 
  if it is available in `Map` or `Exa.Map` (no delegate wrappers).
  However, there are exceptions:
  - `get` is provided
  - `set` is used as an alias for `put`,
     because it adds a guard, and for symmetry with `get`
  - `flush` means delete, but returning the deleted value
  """

  import Exa.Types
  alias Exa.Types, as: E

  # TODO - small space optimization is to make MoS values for 0,1
  #   0 - nil or :empty
  #   1 - id
  #   n - MapSet
  # this will be useful for sparse graphs
  # where there are many keys with count 0,1
  # i.e. nodes with 0,1 neighbors

  # -----
  # types
  # -----

  @empty_set MapSet.new()

  @type key() :: any()

  @typedoc "A Map of Sets (MoS)."
  @type mos(k, v) :: %{k => MapSet.t(v)}

  defguard is_mos(mos) when is_map(mos)

  # -----------
  # constructor
  # -----------

  @doc "Create new MoS."
  @spec new() :: mos(key(), any())
  def new(), do: %{}

  # ---------
  # accessors
  # ---------

  @doc """
  Get the set value for a key.

  If the key does not exist, 
  return the default argument (defaults to empty set).

  The default does not have to be a set.
  For example, using a default of `nil`
  distinguishes between a key with an empty set
  and a missing key.
  """
  @spec get(mos(k, v), k, t) :: t | MapSet.t(v) when t: var, k: var, v: var
  def get(mos, k, default \\ @empty_set), do: Map.get(mos, k, default)

  @doc """
  Test if a value is in the set for a key.
  If the key does not exist, return `false`.
  """
  @spec member?(mos(k, v), k, v) :: bool() when k: var, v: var

  def member?(mos, k, v) when is_map_key(mos, k) do
    mos |> Map.fetch!(k) |> MapSet.member?(v)
  end

  def member?(mos, _k, _v) when is_mos(mos), do: false

  @doc "Find the keys which contain a value."
  @spec find_keys(mos(k, v), v) :: [k] when k: var, v: var
  def find_keys(mos, val) when is_mos(mos) do
    Enum.reduce(mos, [], fn {k, set}, ks ->
      if MapSet.member?(set, val), do: [k | ks], else: ks
    end)
  end

  @doc """
  Get the size of the set value for a key.

  If the key does not exist, 
  return the default argument (defaults 0).

  The default does not have to be an integer.
  For example, using a default of `nil` 
  distinguishes between a key with an empty set
  and a missing key.
  """
  @spec size(mos(k, any()), k, t) :: t | E.count() when t: var, k: var
  def size(mos, k, default \\ 0)

  def size(mos, k, _) when is_map_key(mos, k) do
    mos |> Map.fetch!(k) |> MapSet.size()
  end

  def size(mos, _, default) when is_mos(mos), do: default

  @doc """
  Get the total size of all the sets,
  hence the total number of values.
  """
  @spec sizes(mos(any(), any())) :: E.count()
  def sizes(mos) when is_mos(mos) do
    Enum.reduce(mos, 0, fn {_, vs}, n -> n + MapSet.size(vs) end)
  end

  @doc "Get the union of all the sets."
  @spec union_values(mos(any(), v)) :: MapSet.t(v) when v: var
  def union_values(mos) when is_mos(mos) do
    Enum.reduce(mos, MapSet.new(), fn {_, vs}, set ->
      MapSet.union(set, vs)
    end)
  end

  # -------
  # updates
  # -------

  @doc """
  Set a key to the empty set.
  If the key does not exist, it is added.
  """
  @spec empty(mos(k, v), k) :: mos(k, v) when k: var, v: var
  def empty(mos, k) when is_mos(mos), do: set(mos, k, @empty_set)

  @doc """
  Add a missing key with value of the empty set.

  If the key does not exist, it is added.
  If the key does exist, the value is not changed.
  """
  @spec touch(mos(k, v), k) :: mos(k, v) when k: var, v: var
  def touch(mos, k) when is_map_key(mos, k), do: mos
  def touch(mos, k), do: Map.put(mos, k, @empty_set)

  @doc """
  Set a key to a new set value.

  The new value can be passed as `MapSet` or list.

  If the key does not exist, it is added.
  """
  @spec set(mos(k, v), k, MapSet.t(v) | [v]) :: mos(k, v) when k: var, v: var

  def set(mos, k, vs) when is_mos(mos) and is_struct(vs, MapSet) do
    Map.put(mos, k, vs)
  end

  def set(mos, k, vs) when is_mos(mos) and is_list(vs) do
    # could be any enumerable here
    Map.put(mos, k, MapSet.new(vs))
  end

  @doc """
  Invert the MoS.

  For each entry in the input,
  the key is added to the set of each of its original values.

  The keys of the output will be the union of set values in the input.
  """
  @spec invert(mos(k, v)) :: mos(v, k) when k: var, v: var
  def invert(mos) when is_mos(mos) do
    Enum.reduce(mos, new(), fn {k, set}, out ->
      reduce(out, set, &add(&2, &1, k))
    end)
  end

  @doc """
  Involution for the MoS.

  An involution is a special type of inversion,
  when keys and values are of the same type,
  and the union of values is a subset of the keys.

  Some keys may be empty,
  and some keys may not be referenced by any value.

  The inversion is as follows:
  - all keys are preserved (touched)
  - each key is added to the set for each of its original values

  The output will have the same set of keys as the input.

  An involution is reversible.
  If the involution is applied twice, 
  it will return the original input.
  """
  @spec involute(mos(k, k)) :: mos(k, k) when k: var
  def involute(mos) when is_mos(mos) do
    Enum.reduce(mos, new(), fn {k, set}, out ->
      out |> touch(k) |> reduce(set, &add(&2, &1, k))
    end)
  end

  @doc """
  Merge two entries in the MoS.

  Set the value of the first key 
  to be the union of both key's value sets.
  Delete the second key.

  If the first key does not exist, it is added.
  If neither key exists, 
  the second key will be added with the empty set.
  """
  @spec merge(mos(k,v), k, k) :: mos(k,v) when k: var, v: var
  def merge(mos, k1, k2) do
    set2 = get(mos,k2,@empty_set)
    mos |> adds(k1,set2) |> Map.delete(k2)
  end

  @doc """
  Add a new single value to the set for a key.
  If the key does not exist, it is added.
  """
  @spec add(mos(k, v), k, v) :: mos(k, v) when k: var, v: var
  def add(mos, k, v) when is_mos(mos) do
    new_set = mos |> get(k, @empty_set) |> MapSet.put(v)
    Map.put(mos, k, new_set)
  end

  @doc """
  Add a collection of new values to the set for a key.
  If the key does not exist, it is added.
  """
  @spec adds(mos(k, v), k, MapSet.t(v) | Enumerable.t(v)) :: mos(k, v) when k: var, v: var
  def adds(mos, k, vs) when is_mos(mos) and (is_set(vs) or is_list(vs)) do
    set = get(mos, k, @empty_set) 
    new_set = cond do
      is_set(vs) -> MapSet.union(set,vs)
      true -> MapSet.union(set,MapSet.new(vs))
    end
    Map.put(mos, k, new_set)
  end

  @doc """
  Remove a value from the set for a key.

  It is not an error if the key does not exist, 
  or the value was not found.
  """
  @spec remove(mos(k, v), k, v) :: mos(k, v) when k: var, v: var

  def remove(mos, k, v) when is_mos(mos) and is_map_key(mos, k) do
    new_set = mos |> Map.fetch!(k) |> MapSet.delete(v)
    Map.put(mos, k, new_set)
  end

  def remove(mos, _k, _v) when is_mos(mos), do: mos

  @doc """
  Remove a value from all of the sets.
  """
  @spec remove_all(mos(k, v), v) :: mos(k, v) when k: var, v: var
  def remove_all(mos, v) when is_mos(mos) do
    Enum.reduce(mos, %{}, fn {k, set}, m ->
      Map.put(m, k, MapSet.delete(set, v))
    end)
  end

  @doc """
  Delete a key and return the final value.

  If the key did not exist, return `:no_value` 
  with unchanged MoS argument.
  """
  @spec flush(mos(k, v), k) :: {:no_value | v, mos(k, v)} when k: var, v: var
  def flush(mos, k) when is_map_key(mos, k) do
    {Map.fetch!(mos, k), Map.delete(mos, k)}
  end

  def flush(mos, _) when is_mos(mos), do: {:no_value, mos}

  @doc """
  Reduce over an Mos.

  Just flips the first two arguments of `Enum.reduce/3`
  to supporting piping of MoS.
  """
  @spec reduce(mos(k, v), Enumerable.t(a), (a, mos(k, v) -> mos(k, v))) :: mos(k, v)
        when k: var, v: var, a: var
  def reduce(mos, enum, fun) when is_mos(mos) and is_function(fun, 2) do
    Enum.reduce(enum, mos, fun)
  end
end
