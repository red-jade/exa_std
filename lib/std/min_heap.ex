defprotocol Exa.Std.MinHeap do
  @moduledoc """
  A protocol for minimum heap data structure.

  The entries are key-value pairs sorted by value.
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

  # --------
  # protocol
  # --------

  @doc "Get the number of entries in the heap."
  @spec  size(minheap()) :: E.count()
  def size(heap)

  @doc "Test if the heap has the given key."
  @spec  has_key?(minheap(), key()) :: bool()
  def has_key?(heap, k)

  @doc "Get the value for a key, or return default if the key does not exist."
  @spec  get(minheap(), key(), t) :: val() | t when t: var
  def get(heap, k, default \\ nil)

  @doc "Get the value for a key, or raise if the key does not exist."
  @spec fetch!(minheap(), key()) :: val()
  def fetch!(heap, k)

  @doc """
  Delete a key from the heap.   
  The minimum entry may change.
  """
  @spec  delete(minheap(), key()) :: minheap()
  def delete(heap, k)

  @doc """
  Get the current minimum key-value entry.
  The heap is not modified.
  If the heap does not have any entries, return `:empty`.
  """
  @spec  peek(minheap()) :: :empty | {key(), val()}
  def peek(heap)

  @doc """
  Put a new key-value entry into the heap.
  If the key already exists in the heap, its value is updated.
  The minimum entry may change.
  """
  @spec  push(minheap(), key(), val()) :: minheap()
  def push(heap, k, v)

  @doc """
  Pop the current minimum key-value entry off the heap.
  Return the minimum entry and the modified heap.
  If the heap does not have any entries, return `:empty`.
  """
  @spec  pop(minheap()) :: :empty | {{key(), val()}, minheap()}
  def pop(heap)
end
