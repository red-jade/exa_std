defmodule Exa.Std.Mol do
  @moduledoc """
  Map of Lists (MoL).

  There is a policy of removal-on-empty, 
  and fetch default of empty, to keep the map sparse 
  in the presence of many empty list values.

  An MoL is a Map, so all Map and `Exa.Map` functions can be applied.

  The general policy is not to include a function in MoL 
  if it is available in Map or Exa.Map (no delegate wrappers).
  However, there are exceptions:
  - `get` is provided
  - `set` is used as an alias for `put`,
     because it adds a guard `is_list`, 
     and for symmetry with `get`
  - `flush` means delete, but returning the deleted value
  """

  alias Exa.Types, as: E

  # -----
  # types
  # -----

  @type key() :: any()

  @type mol() :: %{key() => list()}
  defguard is_mol(mol) when is_map(mol)

  # -----------
  # constructor
  # -----------

  @doc "Create new MoL."
  @spec new() :: mol()
  def new(), do: %{}

  # ---------
  # accessors
  # ---------

  @doc """
  Get the value for a key.

  If the key does not exist, 
  return the default argument (defaults to empty list).

  The default does not have to be a list.
  For example, using a default of `nil`
  distinguishes between a key with an empty list
  and a missing key.
  """
  @spec get(mol(), key(), any()) :: any()
  def get(mol, k, default \\ []), do: Map.get(mol, k, default)

  @doc """
  Get the length of the list value for a key.
  If the key does not exist, return `nil`.
  """
  @spec length(mol(), key()) :: nil | E.count()
  def length(mol, k) when is_map_key(mol, k), do: mol |> get(k) |> length()
  def length(_, _), do: nil

  @doc """
  Get the total length of all the lists,
  hence the total number of values.
  """
  @spec lengths(mol()) :: E.count()
  def lengths(mol), do: Enum.reduce(mol, 0, fn {_, vs}, n -> n + length(vs) end)

  # -------
  # updates
  # -------

  @doc """
  Set a key to the empty list.
  If the key does not exist, it is added.
  """
  @spec empty(mol(), key()) :: mol()
  def empty(mol, k), do: set(mol, k, [])

  @doc """
  Set a key to a new list value.
  If the key does not exist, it is added.
  If the list is empty, the key is deleted.
  """
  @spec set(mol(), key(), list()) :: mol()
  def set(mol, k, []), do: Map.delete(mol, k)
  def set(mol, k, vs) when is_list(vs), do: Map.put(mol, k, vs)

  @doc """
  Add a new single value to the beginning of the list (prepend).
  If the key does not exist, it is added.
  """
  @spec add(mol(), key(), any()) :: mol()
  def add(mol, k, v), do: prepend(mol, k, v)

  @doc """
  Delete the first occurrence of a value from the list.

  If the resulting list is empty, delete the key.

  It is an error if the key does not exist, 
  or the value was not found.
  """
  @spec remove(mol(), key(), any()) :: mol() | :error
  def remove(mol, k, v) do
    vals = get(mol, k)
    if v not in vals, do: :error, else: set(mol, k, List.delete(vals, v))
  end

  @doc """
  Remove all occurrences of a value from the list.

  If the resulting list is empty, delete the key.
  """
  @spec remove_all(mol(), key(), any()) :: mol()
  def remove_all(mol, k, v) do
    case get(mol, k) do
      [] ->
        mol

      vals ->
        case Exa.List.delete_all(vals, v) do
          {:no_match, _} -> mol
          {:ok, dels} -> set(mol, k, dels)
        end
    end
  end

  @doc """
  Prepend a new single value to the beginning of the list.
  If the key does not exist, it is added.
  """
  @spec prepend(mol(), key(), any()) :: mol()
  def prepend(mol, k, v), do: set(mol, k, [v | get(mol, k)])

  @doc """
  Prepend a list to the beginning of the list.
  If the key does not exist, it is added.
  """
  @spec prepends(mol(), key(), list()) :: mol()
  def prepends(mol, k, vs) when is_list(vs), do: set(mol, k, vs ++ get(mol, k))

  @doc """
  Append a new value to the end of the list.
  If the key does not exist, it is added.
  """
  @spec append(mol(), key(), any()) :: mol()
  def append(mol, k, v), do: appends(mol, k, [v])

  @doc """
  Append a list to the end of the list.
  If the key does not exist, it is added.
  """
  @spec appends(mol(), key(), any()) :: mol()
  def appends(mol, k, vs), do: set(mol, k, get(mol, k) ++ vs)

  @doc "Reverse all lists in the MoL."
  @spec reverse(mol()) :: mol()
  def reverse(mol), do: Exa.Map.map(mol, &Enum.reverse/1)

  @doc "Sort all lists in the MoL."
  @spec sort(mol()) :: mol()
  def sort(mol), do: Exa.Map.map(mol, &Enum.sort/1)

  @doc """
  Take the first entry (head) of the list, 
  and remove it from the values.
  If the list is a singleton and the head is the only element,
  then remove the key entry from the map.

  If the key is missing, or the list is empty, then return `:error`.
  """
  @spec take_hd(mol(), key()) :: {:ok, any(), mol()} | :error
  def take_hd(mol, k) do
    case get(mol, k) do
      [] -> :error
      [h] -> {:ok, h, Map.delete(mol, k)}
      [h | t] -> {:ok, h, set(mol, k, t)}
    end
  end

  @doc """
  Delete a key and return the final value.

  If the key did not exist, return `:no_value`.
  """
  @spec flush(mol(), key()) :: {:no_value | any(), mol()}
  def flush(mol, k) do
    val =
      case Map.fetch(mol, k) do
        {:ok, v} -> v
        :error -> :no_value
      end

    {val, Map.delete(mol, k)}
  end
end
