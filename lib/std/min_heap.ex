defprotocol Exa.Std.MinHeap do
  @moduledoc """
  A protocol for minimum heap data structure.

  The entries are key-value pairs sorted by numerical value,
  so the heap is a minimum sorted map.

  It can be useful to initialize the heap with 
  _infinite_ maximum values,
  so the value is allowed to be the atom `:inf`,
  which sorts higher than any number.

  Note the distinct behavior of `add/3` and `update/3`.
  It is the client's responsibility to use `add/3` 
  for a new key, and `update/3` when the key already exists.
  There is no general `put` function, 
  which supports flexible add-or-update (like `Map.put/3`).
  The reason is that some implementations of the protocol
  do not have an O(1) way to test for an existing key.
  """

  alias Exa.Types, as: E

  # -----
  # types
  # -----

  # keys can be anything, but will usually be non-negative integers
  @type key() :: any()

  # note that all numbers sort less than atoms, so x < :inf
  @type val() :: number() | :inf

  # min heap is any struct that implements the protocol
  @type minheap() :: map()

  # tuples and maps ----------

  # regular kv tuple
  @type kvtup() :: {key(), val()}

  # reversed vk tuple that sorts with the value
  @type vktup() :: {val(), key()}

  # regular kv map
  @type kvmap() :: %{key() => val()}

  # --------
  # protocol
  # --------

  @doc "Get the number of entries in the heap."
  @spec size(minheap()) :: E.count()
  def size(heap)

  @doc "Test if the heap has the given key."
  @spec has_key?(minheap(), key()) :: bool()
  def has_key?(heap, k)

  @doc "Get the value for a key, or return default if the key does not exist."
  @spec get(minheap(), key(), t) :: val() | t when t: var
  def get(heap, k, default \\ nil)

  @doc "Get the value for a key, or raise if the key does not exist."
  @spec fetch!(minheap(), key()) :: val()
  def fetch!(heap, k)

  @doc """
  Delete a key from the heap.   

  The minimum entry may change.

  It is not an error if the key does not exist. 
  The heap is returned unchanged.
  """
  @spec delete(minheap(), key()) :: minheap()
  def delete(heap, k)

  @doc """
  Add a new key-value entry to the heap.

  The minimum entry may change.

  The client must ensure that the key is new.
  If the key already exists, use `update/3`.

  An implementation may optionally check for an existing key
  and raise an error - if the check can be done in O(1).
  """
  @spec add(minheap(), key(), val()) :: minheap()
  def add(heap, k, v \\ :inf)

  @doc """
  Update an existing key-value entry in the heap.

  The minimum entry may change.

  The client must ensure that the key already exists.
  If the key does not already exist, use `add/3`.

  An implementation may optionally check for a missing key
  and raise an error - if the check can be done in O(1).
  """
  @spec update(minheap(), key(), val()) :: minheap()
  def update(heap, k, v)

  @doc """
  Get the current minimum key-value entry.

  The heap is not modified.

  If the heap does not have any entries, returns `:empty`.
  """
  @spec peek(minheap()) :: :empty | {key(), val()}
  def peek(heap)

  @doc """
  Pop the current minimum key-value entry off the heap.

  Returns the minimum entry and the modified heap.

  If the heap does not have any entries, return `:empty`.
  """
  @spec pop(minheap()) :: :empty | {{key(), val()}, minheap()}
  def pop(heap)

  @doc "Get the list of keys in arbitrary order."
  @spec to_list(minheap()) :: [MH.key()]
  def keys(heap)

  @doc "Serialize to a list in arbitrary order."
  @spec to_list(minheap()) :: [kvtup()]
  def to_list(heap)

  @doc "Serialize to a map."
  @spec to_map(minheap()) :: kvmap()
  def to_map(heap)
end
