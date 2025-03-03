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

  import Exa.Std.Mol, only: [is_mol: 1]
  alias Exa.Std.Mol, as: M
  alias Exa.Std.Mol

  # TODO - small space optimization is to make 
  #        special MoS values for 0,1 cardinality
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

  @doc "Create a new MoS from an MoL."
  @spec from_mol(M.mol(k, v)) :: mos(k, v) when k: var, v: var
  def from_mol(mol) when is_mol(mol) do
    Enum.reduce(mol, new(), fn {k, vs}, mos -> set(mos, k, vs) end)
  end

  @doc """
  Create a new MoL from an MoS.
  The order of the new list values is unspecified.
  Use `Exa.Mol.sort/1` to sort the list values.
  """
  @spec to_mol(mos(k, v)) :: M.mol(k, v) when k: var, v: var
  def to_mol(mos) when is_mos(mos) do
    Enum.reduce(mos, Mol.new(), fn {k, vs}, mol -> Mol.set(mol, k, vs) end)
  end

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
  Get the total size of all the sets.

  If all the sets are disjoint, 
  then it will also be the total number of unique values.
  """
  @spec sizes(mos(key(), any())) :: E.count()
  def sizes(mos) when is_mos(mos) do
    Enum.reduce(mos, 0, fn {_, vs}, n -> n + MapSet.size(vs) end)
  end

  @doc """
  Get the total number of unique values,
  which is the size of the union of all sets.
  """
  @spec sizes_unique(mos(key(), any())) :: E.count()
  def sizes_unique(mos) when is_mos(mos) do
    mos |> union_values() |> MapSet.size()
  end

  @doc "Get the union of all the sets."
  @spec union_values(mos(key(), v)) :: MapSet.t(v) when v: var
  def union_values(mos) when is_mos(mos) do
    Enum.reduce(mos, MapSet.new(), fn {_, vs}, set ->
      MapSet.union(set, vs)
    end)
  end

  @doc """
  Index by size.

  Return a map of set size (non-negative integer) 
  to a set of the keys that have that size.

  If the MoS is empty, return the empty MoS.
  """
  @spec index_size(Mos.mos(k, any())) :: Mos.mos(E.count1(), k) when k: var
  def index_size(mos) when is_mos(mos) do
    Enum.reduce(mos, new(), fn {k, vs}, ind -> add(ind, MapSet.size(vs), k) end)
  end

  @doc """
  Test if an MoS is a disjoint partition, 
  where all values only occur once.

  The empty MoS returns `true`.
  """
  @spec disjoint?(Mos.mos(any(), any())) :: bool()
  def disjoint?(mos) when is_mos(mos) do
    union =
      Enum.reduce_while(mos, MapSet.new(), fn {_, vs}, set ->
        if MapSet.disjoint?(vs, set) do
          {:cont, MapSet.union(set, vs)}
        else
          {:halt, %{}}
        end
      end)

    map_size(union) != 0
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

  The new value can be passed as `MapSet` 
  or another scalar enumerable (e.g. list, range).

  If the key does not exist, it is added.
  """
  @spec set(mos(k, v), k, MapSet.t(v) | Enumerable.t(v)) :: mos(k, v) when k: var, v: var
  def set(mos, k, vs) when is_mos(mos) and is_set(vs), do: Map.put(mos, k, vs)
  def set(mos, k, vs) when is_mos(mos), do: Map.put(mos, k, MapSet.new(vs))

  @doc """
  Invert the MoS.

  For each entry in the input,
  the key is added to the set of each of its original values.

  The keys of the output will be the union of set values in the input.
  """
  @spec invert(mos(k, v)) :: mos(v, k) when k: var, v: var
  def invert(mos) when is_mos(mos) do
    Enum.reduce(mos, new(), fn {k, set}, out ->
      Enum.reduce(set, out, &add(&2, &1, k))
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

  An involution is reversible:
  if the involution is applied twice, 
  it will return the original input.
  """
  @spec involute(mos(k, k)) :: mos(k, k) when k: var
  def involute(mos) when is_mos(mos) do
    Enum.reduce(mos, new(), fn {k, set}, out ->
      out |> touch(k) |> reduce(set, &add(&2, &1, k))
    end)
  end

  @doc """
  Merge two entries in an MoS.

  Set the value of the first key 
  to be the union of both key's value sets.
  Delete the second key.

  If the first key does not exist, 
  it is added with the value of the second key.

  If the second key does not exist, the map is unchanged.
  """
  @spec merge(mos(k, v), k, k) :: mos(k, v) when k: var, v: var

  def merge(mos, k1, k2) when is_map_key(mos, k2) do
    set2 = Map.fetch!(mos, k2)
    mos |> adds(k1, set2) |> Map.delete(k2)
  end

  def merge(mos, _, _), do: mos

  @doc """
  Merge two MoS.

  The result will have the union of boths sets of keys.
  Distinct keys are added with their existing set values.
  Equal keys will be given the union of their existing set values.
  """
  @spec merge(mos(k, v), mos(k, v)) :: mos(k, v) when k: var, v: var
  def merge(mos1, mos2) do
    Map.merge(mos1, mos2, fn _, set1, set2 -> MapSet.union(set1, set2) end)
  end

  @doc """
  Add a new single value to the set for a key.
  If the key does not exist, it is added.
  """
  @spec add(mos(k, v), k, v) :: mos(k, v) when k: var, v: var
  def add(mos, k, v) when is_mos(mos) do
    new_set = mos |> get(k) |> MapSet.put(v)
    Map.put(mos, k, new_set)
  end

  @doc """
  Add a collection of new values to the set for a key.

  The collection should be a set, 
  or another scalar enumerable (e.g. list, range).

  If the key does not exist, it is added.
  """
  @spec adds(mos(k, v), k, MapSet.t(v) | Enumerable.t(v)) :: mos(k, v) when k: var, v: var
  def adds(mos, k, vs) when is_mos(mos) and (is_set(vs) or is_list(vs) or is_range(vs)) do
    set = get(mos, k)
    col = if is_set(vs), do: vs, else: MapSet.new(vs)
    Map.put(mos, k, MapSet.union(set, col))
  end

  @doc """
  Pick a value from the set, 
  and remove it from the values.

  If the set value becomes empty, the entry is not removed.

  If the key is empty or missing, return `:error`.

  Assume the Axion of Choice :)
  """
  @spec pick(mos(k, v), k) :: {v, Mol.mol(k, v)} | :error when k: var, v: var
  def pick(mos, k) do
    vs = get(mos, k)

    if MapSet.size(vs) == 0 do
      :error
    else
      {h, rem} = Exa.Set.pick(vs)
      {h, set(mos, k, rem)}
    end
  end

  @doc """
  Remove a value from the set for a key.

  If the set value becomes empty, the entry is not removed.

  It is not an error if the key does not exist, 
  or the value was not found.
  In those cases, the argument is returned unchanged.
  """
  @spec remove(mos(k, v), k, v) :: mos(k, v) when k: var, v: var

  def remove(mos, k, v) when is_mos(mos) and is_map_key(mos, k) do
    new_set = mos |> Map.fetch!(k) |> MapSet.delete(v)
    Map.put(mos, k, new_set)
  end

  def remove(mos, _k, _v) when is_mos(mos), do: mos

  @doc """
  Remove a collection of values from the set for a key.

  The collection should be a set, list or range.

  If the set value becomes empty, the entry is not removed.

  It is not an error if the key does not exist, 
  or the values were not found.
  In those cases, the argument is returned unchanged.
  """
  @spec removes(mos(k, v), k, MapSet.t(v) | Enumerable.t(v)) :: mos(k, v) when k: var, v: var

  def removes(mos, k, vs)
      when is_mos(mos) and is_map_key(mos, k) and
             (is_set(vs) or is_list(vs) or is_range(vs)) do
    set = get(mos, k)
    col = if is_set(vs), do: vs, else: MapSet.new(vs)
    Map.put(mos, k, MapSet.difference(set, col))
  end

  def removes(mos, _k, _vs) when is_mos(mos), do: mos

  @doc """
  Remove a value from all of the sets for all keys.
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
