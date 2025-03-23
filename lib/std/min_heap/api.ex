defmodule Exa.Std.MinHeap.Api do
  @moduledoc """
  A behaviour for minimum heap data structure.

  The entries are key-value pairs sorted by value.
  """

  alias Exa.Types, as: E

  # -----
  # types
  # -----

  # implementation module tag for dispatching 
  @typep tag() :: :mh_map | :mh_ord 

  # keys can be anything, but will usually be non-negative integers
  @type key() :: any()

  # note that all numbers sort less than atoms, so x < :inf
  @type val() :: :inf | number()

  # min heap is a tagged tuple
  # different implementations will have different internal representations
  @type minheap() :: {tag(), any()}

  # ---------
  # behaviour
  # ---------

  @doc "Create a new heap."
  @callback new(tag()) :: minheap()

  @doc "Get the number of entries in the heap."
  @callback size(minheap()) :: E.count()

  @doc "Test if the heap has the given key."
  @callback has_key?(minheap(), key()) :: bool()

  @doc "Get the value for a key, or return default if the key does not exist."
  @callback get(minheap(), key(), t) :: val() | t when t: var

  @doc """
  Delete a key from the heap.   
  The minimum entry may change.
  """
  @callback delete(minheap(), key()) :: minheap()

  @doc """
  Get the current minimum key-value entry.
  The heap is not modified.
  If the heap does not have any entries, return `:empty`.
  """
  @callback peek(minheap()) :: :empty | {key(), val()}

  @doc """
  Put a new key-value entry into the heap.
  If the key already exists in the heap, its value is updated.
  The minimum entry may change.
  """
  @callback push(minheap(), key(), val()) :: minheap()

  @doc """
  Pop the current minimum key-value entry off the heap.
  Return the minimum entry and the modified heap.
  If the heap does not have any entries, return `:empty`.
  """
  @callback pop(minheap()) :: :empty | {{key(), val()}, minheap()}
end
