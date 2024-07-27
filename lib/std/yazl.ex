defmodule Exa.Std.Yazl do
  @moduledoc """
  A mutable list with a current focus position.

  Reference: 
  _Functional Pearl: The Zipper_, 
  Gérard Huet, 1997 
  \[[pdf](https://www.st.cs.uni-saarland.de/edu/seminare/2005/advanced-fp/docs/huet-zipper.pdf)\]

  A yazl supports operations normally found in
  mutable doubly-linked lists, such as read, update,
  insert, delete and incremental bi-directional traversal.

  Local operations in the neighborhood of the focus
  are executed in O(1) constant time.

  The yazl also provides global operations and index-based
  random access, typically with an O(n) performance penalty.

  The focus may be between two elements of the list, or at one of the ends.
  The descriptions used here are slightly different from a true zipper,
  because the focus is between elements, not at a current element.

  We describe lists as being ordered left-to-right,
  like western writing, with the excuse that this bias is already
  present in Erlang with the names _foldl_, _foldr_.

  The current value is chosen as left `:ldir` 
  or right `:rdir` (default) of the current focus.

  The position of the current element to the left `:ldir` or right `rdir` 
  is either a 0-based non-negative integer,
  or an end marker: `:endl`, for the beginning, or `:endr` for the end.

  ![yazl](./assets/yazl.png)

  There is no current value for:
  - any direction on empty lists
  - `:rdir` when the focus is after the last element
  - `:ldir` when the focus is before the first element

  Functions on single values and lists of values are not overloaded,
  they are given distinct names (_e.g._`insert`/`inserts`),
  so that yazls can have lists as regular elements
  (_i.e._ lists of lists).

  ## Usage 

  ### Create, Import, Export 

  Create yazls from lists using `new/0`, `new/1`, `new/2`, 
  `from_list/1` and `from_lists/2`.
  Recover the underlying list with `to_list/1` or `to_lists/1`.

  ### Query 

  Test if a term appears to be a yazl with the `is_yazl/1` guard.
  Test if it is empty with `is_empty/1`.
  Get the total length of the underlying list using `size/1`.
  Find the current focus location using `position`,
  which may return a 0-based integer index, or an ending marker.
  Read the value(s) at the current focus position using `get/2` or `gets/3`.

  ### Move 

  Movement functions change the focus position,
  but do not change the content of the list.

  The `move/2` function changes focus to the next or previous elements.

  The `moves/3` function jumps multiple steps relative to the current focus.

  The `move_to/2` function jump to absolute positions based on
  a specific index, or the beginning or end of the list.

  Client code can implement cyclic behaviour by using
  a combination of `move/2` and `move_to/2` functions.

  ### Search

  Move the focus by searching with `find/3`, `finds/3`, `move_until/3`.
  The `find/3` function will search for the next or previous
  occurrence of a value. The `finds/3` function searches for the
  next or previous occurrence of a sequence of values.
  The `move_until/2` functions search until a
  boolean predicate function of the current value becomes true.

  ### Update 

  Write the value(s) at the current focus position using `set/3` and `sets/3`.

  Add new values on either side of the current focus,
  or at the head or tail of the underlying list, using
  `insert/3` and `inserts/3`.

  Delete the element at the current focus position using `delete/2`.
  Delete from the focus to one of the ends using the `truncate/2`.

  Reverse the whole list while keeping the same focus
  using `reverse` - note this is constant time O(1).

  ### Function Application 

  Apply a _map_ function while leaving the focus unchanged.

  ## Efficiency

  The implementation is efficient constant time, O(1):
  for local operations at the focus: <br>
  `new`, `move`, `get`, `set`, `insert`, `inserts`,
   `delete`, `reverse`, `truncate`.

  Incremental operations will incur an O(m) cost proportional
  to the distance from the focus to the target position:<br>
  `from_list`, `from_lists`, `gets`, `sets`, `moves`, `move_to`,
  `move_until`, `find`, `finds`, `inserts`.

  Global operations will incur a cost proportional to the
  length of the underlying list O(n): <br>
  `to_list`, `size`, `position`.
  """
  import Exa.Types
  alias Exa.Types, as: E

  # -----
  # types
  # -----

  @typedoc "A yazl is a tuple of two lists."
  @type yazl(a) :: {[a], [a]}

  @doc "Test if a term appears to be a yazl."
  defguard is_yazl(z) when is_fix_tuple(z, 2) and is_list(elem(z, 0)) and is_list(elem(z, 1))

  @doc "Test if a term is an empty yazl."
  defguard is_empty(z) when z == {[], []}

  @typedoc "An empty yazl is just two empty lists."
  @type empty_yazl() :: {[], []}

  @typedoc """
  Directions are to the left (beginning) 
  or to the right (end) of the list.
  """
  @type direction() :: :ldir | :rdir

  @typedoc """
  A position before the left (beginning) 
  or past the right (end) of the list.
  """
  @type ending() :: :endl | :endr

  @typedoc """
  A 0-based index of a position in the list.
  The value will be between 0 and `size`, inclusive.
  """
  @type index() :: E.index0()

  @typedoc "Expand a generic type to include the two endings."
  @type endable(a) :: ending() | a

  @typedoc """
  A position for the focus at an index or one of the ends.
  """
  @type position() :: endable(index())

  # ----------
  # type utils
  # ----------

  @doc "Type utility: get the opposite of a direction."
  @spec opposite(direction()) :: direction()
  def opposite(:rdir), do: :ldir
  def opposite(:ldir), do: :rdir

  @doc "Type utility: get the end in a specific direction."
  @spec ending(direction()) :: ending()
  def ending(:rdir), do: :endr
  def ending(:ldir), do: :endl

  # -----------
  # constructor
  # -----------

  @doc "Constructor: create a new empty yazl."
  @spec new() :: empty_yazl()
  def new(), do: {[], []}

  @doc """
  Constructor: create a yazl with focus before the first element. 

  If the list is empty, the empty yazl is returned.

  Equivalent to calling `new/2` with position argument `:endl`.
  """
  @spec new([a]) :: yazl(a) when a: var
  def new(lst) when is_list(lst), do: {[], lst}

  @doc """
  Constructor: create a yazl with focus at the
  beginning, at the end, or before the Ith element of a list.

  The index is 0-based, so the first element is 0,
  and the last index is equal to the length of the list minus 1.

  To position at the beginning of the list, pass `:endl`,
  or `0` if the yazl is not empty.

  To position at the end of the list, pass `:endr`.

  It is an error to pass an integer less than 0,
  or greater than or equal to the length of the list.
  For example, passing 0 with the empty list is an error.

  If the list is empty, the empty yazl is returned.

  The current value is implicitly to the right (after)
  the focus position. 
  """
  @spec new([a], position()) :: yazl(a) when a: var
  def new(lst, :endl) when is_list(lst), do: {[], lst}
  def new(lst, :endr) when is_list(lst), do: {Enum.reverse(lst), []}
  def new(lst, i) when is_list(lst) and is_integer(i), do: do_new(lst, i)

  defp do_new(lst, i) when i < 0, do: new(lst, :endl)
  defp do_new(lst, i) when i >= length(lst), do: new(lst, :endr)
  defp do_new(lst, i), do: take([], i, lst)

  defp take(l, 0, r), do: {l, r}
  defp take(l, i, [x | r]), do: take([x | l], i - 1, r)

  # -----------
  # conversions
  # -----------

  @doc """
  Constructor: create a yazl with focus between two sublists.

  The underlying list will be the concatenation of the two lists.
  The focus will be after (right of) the last element of the first list,
  and before (left of) the first element of the second list.
  If both lists are empty, the empty yazl is returned.
  """
  @spec from_lists([a], [a]) :: yazl(a) when a: var
  def from_lists(l, r) when is_list(l) and is_list(r), do: {Enum.reverse(l), r}

  @doc """
  Recover the underlying list.

  If the yazl is empty, the result is the empty list.

  The cost is proportional to the position in the list.
  If the focus is at `:endl` it is O(1),
  but if the focus is at `:endr` it is O(n).
  """
  @spec to_list(yazl(a)) :: [a] when a: var
  def to_list({[], []}), do: []
  def to_list({l, r}), do: Enum.reverse(l, r)

  @doc """
  Recover the underlying sublists before and after the focus.

  The ordering of each list is correct for the whole sequence,
  so the underlying list is equal to the 
  concatenation of the two result lists.

  If the yazl is empty, the result is two empty lists.

  The cost is proportional to the position in the list. 
  If the focus is at `:endl` it is O(1),
  but if the focus is at `:endr` it is O(n).
  """
  @spec to_lists(yazl(a)) :: {[a], [a]} when a: var
  def to_lists({[], []} = empty), do: empty
  def to_lists({l, r}), do: {Enum.reverse(l), r}

  @doc """
  Reverse a yazl keeping the same focus position 
  with respect to the content.

  Performance is O(1).
  """
  @spec reverse(yazl(a)) :: yazl(a) when a: var
  def reverse({l, r}), do: {r, l}

  # -------
  # queries
  # -------

  @doc """
  Get the length of the underlying list.

  If the yazl is empty, the size is 0.

  The performance is O(n).
  """
  @spec size(yazl(_)) :: E.count() when _: var
  def size({[], []}), do: 0
  def size({l, r}), do: length(l) + length(r)

  @doc """
  Get the one-based index of the position to
  the right or left of the current focus.

  Indices are 0-based.

  If the yazl is empty, or focus is at the beginning of
  a non-empty list, then the left index is `:endl`.

  If the yazl is at the end of a non-empty list,
  then the right index is `:endr`.

  The performance is proportional to the position in the list.
  If the focus is at `:endl` it is O(1),
  but if the focus is at the last element, it is O(n).
  """
  @spec pos(yazl(_), direction()) :: position() when _: var
  def pos(yazl, dir \\ :rdir)
  def pos({[], _}, :ldir), do: :endl
  def pos({_, []}, :rdir), do: :endr
  def pos({l, _}, :ldir), do: length(l) - 1
  def pos({l, _}, :rdir), do: length(l)

  @doc """
  Get the value of the element to the right or
  left of the current focus.

  If the operation would overrun the begining or end
  of the list, return `:endr` or `:endl`.
  This is fast constant time O(1).
  """
  @spec get(yazl(a), direction()) :: endable(a) when a: var
  def get(yazl, dir \\ :rdir)
  def get({_, []}, :rdir), do: :endr
  def get({[], _}, :ldir), do: :endl
  def get({_, [h | _]}, :rdir), do: h
  def get({[h | _], _}, :ldir), do: h

  @doc """
  Get the values of elements to the right or
  left of the current focus.

  Getting zero elements returns the empty list.

  Getting a negative number of elements,
  returns elements from the other direction.
  The return values are always in the 
  forward order of the full list.

  If the operation would overrun the begining or end
  of the list, return `:endr` or `:endl`.

  Performance is proportional to the length of the requested sublist.
  """
  @spec gets(yazl(a), integer(), direction()) :: [a] when a: var
  def gets(yazl, n, dir \\ :rdir)
  def gets(_, 0, _), do: []
  def gets(z, 1, dir), do: [get(z, dir)]
  def gets(z, n, dir) when n < 0, do: gets(z, -n, opposite(dir))
  def gets({_, r}, n, :rdir) when n > length(r), do: :endr
  def gets({l, _}, n, :ldir) when n > length(l), do: :endl
  def gets({_, r}, n, :rdir), do: Enum.take(r, n)
  def gets({l, _}, n, :ldir), do: Enum.reverse(Enum.take(l, n))

  # ----------
  # move focus
  # ----------

  @doc """
  Move the focus one step to the right or left.

  If the operation would step beyond the begining or end
  of the list, return the original list.

  The result is always a yazl 
  (not an end marker `:endl` or `:endr`).

  Traditional functions are equivalent as:
  - `next(z)` is `move(z, :rdir)`
  - `prev(z)` is `move(z, :ldir)`

  This is fast constant time O(1).
  """
  @spec move(yazl(a), direction()) :: yazl(a) when a: var
  def move({_, []} = z, :rdir), do: z
  def move({[], _} = z, :ldir), do: z
  def move({l, [h | r]}, :rdir), do: {[h | l], r}
  def move({[h | l], r}, :ldir), do: {l, [h | r]}

  @doc """
  Move the focus multiple steps to the right or left.

  Moving a zero offset leaves the yazl unchanged.

  If the operation would step beyond the begining or end
  of the list, return the original list.

  The result is always a yazl 
  (not an end marker `:endl` or `:endr`).

  Negative offsets are converted to the equivalent positive
  offset in the other direction.

  Performance is O(n).
  """
  @spec moves(yazl(a), integer(), direction()) :: yazl(a) when a: var

  def moves({[], []} = z, _, _), do: z
  def moves(z, 0, _), do: z
  def moves(z, 1, dir), do: move(z, dir)
  def moves(z, i, dir) when i < 0, do: moves(z, -i, opposite(dir))

  def moves({l, r}, i, :rdir) when i < length(r) do
    {rh, rt} = Enum.split(r, i)
    {Enum.reverse(rh, l), rt}
  end

  def moves({l, r}, i, :ldir) when i < length(l) do
    {lh, lt} = Enum.split(l, i)
    {lt, Enum.reverse(lh, r)}
  end

  def moves(z, _, :rdir), do: move_to(z, :endr)
  def moves(z, _, :ldir), do: move_to(z, :endl)

  @doc """
  Move to an absolute position, either:
  - beginning or end of the list
  - 0-based index position within the list

  The index position sets the focus with 
  `:rdir` (after) position equal to the index.

  The result is always a yazl 
  (not an end marker `:endl` or `:endr`).

  Equivalent to: `z |> to_list() |> new(pos)`
  """
  @spec move_to(yazl(a), position()) :: yazl(a) when a: var

  # are these faster than the naive implementation?
  # z |> to_list() |> new(pos)

  def move_to({[], []} = z, _), do: z
  def move_to({_, []} = z, :endr), do: z
  def move_to({[], _} = z, :endl), do: z

  def move_to({l, r}, :endr), do: {Enum.reverse(r, l), []}
  def move_to({l, r}, :endl), do: {[], Enum.reverse(l, r)}

  def move_to({_, _} = z, i) when is_integer(i) do
    len = size(z)

    ir =
      case pos(z, :rdir) do
        :endr -> len
        ir -> ir
      end

    cond do
      i <= 0 -> move_to(z, :endl)
      i >= len -> move_to(z, :endr)
      true -> moves(z, i - ir, :rdir)
    end
  end

  @doc """
  Search for the first occurrence of a value
  that satisfies a boolean predicate function.

  If the search is successful, it returns a yazl
  that focuses before (after) the found element.

  If the search does not find the value,
  then it returns `:endr` or `:endl`.
  """
  @spec move_until(yazl(a), E.predicate?(a), direction()) :: endable(yazl(a)) when a: var
  def move_until(yazl, pred, dir \\ :rdir)

  def move_until({_, []}, _, :rdir), do: :endr
  def move_until({[], _}, _, :ldir), do: :endl

  def move_until({_, [rh | _]} = z, pred, :rdir) do
    if pred.(rh), do: z, else: move_until(move(z, :rdir), pred, :rdir)
  end

  def move_until({[lh | _], _} = z, pred, :ldir) do
    if pred.(lh), do: z, else: move_until(move(z, :ldir), pred, :ldir)
  end

  # ------
  # search
  # ------

  @doc """
  Search for the first occurrence of a value.

  If the search is successful, return a yazl that
  focuses before (right search) or after (left search)
  the found element.

  If the search does not find the value,
  then it returns `:endr` or `:endl`.
  """
  @spec find(yazl(a), a, direction()) :: endable(yazl(a)) when a: var
  def find(yazl, val, dir \\ :rdir)
  def find({_, []}, _, :rdir), do: :endr
  def find({[], _}, _, :ldir), do: :endl
  def find({_, [val | _]} = z, val, :rdir), do: z
  def find({[val | _], _} = z, val, :ldir), do: z
  def find(z, val, dir), do: find(move(z, dir), val, dir)

  @doc """
  Search for the first sequence of values
  that match a given target list.

  The search always matches content in the forward direction.

  If the search is successful, return a yazl:
  - `:rdir` gives focus before start of target  
  - `:ldir` gives focus after end of target 

  If the search does not find the value,
  then it returns `:endr` or `:endl`.

  A search for the empty list always returns the input yazl,
  because the empty list is always a prefix of any list
  (follows behavior of `List.starts_with?/2`).
  """
  @spec finds(yazl(a), [a], direction()) :: endable(yazl(a)) when a: var
  def finds(yazl, vs, dir \\ :rdir) when is_list(vs) do
    do_finds(yazl, vs, length(vs), dir)
  end

  defp do_finds(z, [], _, _), do: z
  defp do_finds({_, l}, _, nv, :rdir) when length(l) < nv, do: :endr
  defp do_finds({r, _}, _, nv, :ldir) when length(r) < nv, do: :endl

  defp do_finds(z, [v | vt] = vs, nv, :rdir) do
    case find(z, v, :rdir) do
      :endr ->
        :endr

      {_, [^v | rt]} = find ->
        cond do
          List.starts_with?(rt, vt) -> find
          true -> do_finds(move(z, :rdir), vs, nv, :rdir)
        end
    end
  end

  defp do_finds(z, vs, nv, :ldir) do
    case do_finds(reverse(z), Enum.reverse(vs), nv, :rdir) do
      :endr -> :endl
      y -> reverse(y)
    end
  end

  # ------
  # update
  # ------

  @doc """
  Set the value of the element to the right or
  left of the current focus.

  If the operation would overrun the begining or end
  of the list, return `:endr` or `:endl`.

  This is fast constant time O(1).
  """
  @spec set(yazl(a), a, direction()) :: endable(yazl(a)) when a: var
  def set(yazl, val, dir \\ :rdir)
  def set({_, []}, _, :rdir), do: :endr
  def set({[], _}, _, :ldir), do: :endl
  def set({l, [_ | rt]}, v, :rdir), do: {l, [v | rt]}
  def set({[_ | lt], r}, v, :ldir), do: {[v | lt], r}

  @doc """
  Set values of elements to the right or
  left of the current focus.

  Setting the empty list is a no-op,
  and returns the original yazl.

  If the operation would overrun the begining or end
  of the list, return `:endr` or `:endl`.

  Performance is up to O(n+m) for m new values, where m > 1
  """
  @spec sets(yazl(a), [a], direction()) :: endable(yazl(a)) when a: var
  def sets(yazl, vals, dir \\ :rdir)

  def sets(z, [], _), do: z

  def sets(z, [v], dir), do: set(z, v, dir)

  def sets({l, r}, vs, :rdir) do
    nv = length(vs)

    cond do
      nv > length(r) -> :endr
      true -> {l, vs ++ Enum.drop(r, nv)}
    end
  end

  def sets({l, r}, vs, :ldir) do
    nv = length(vs)

    cond do
      nv > length(l) -> :endl
      true -> {Enum.reverse(vs, Enum.drop(l, nv)), r}
    end
  end

  @doc """
  Insert a value of the element to the 
  right or left of the current focus, 
  or at the beginning or end of the whole list.

  For local insertion at the focus,
  whether the value is put to the left or right
  does not affect the final content of the list,
  just the final position of the focus
  relative to the new inserted value.

  This is fast constant time O(1).
  """
  @spec insert(yazl(a), a, direction() | ending()) :: yazl(a) when a: var
  def insert(yazl, val, dir \\ :rdir)
  def insert({l, r}, v, :rdir), do: {l, [v | r]}
  def insert({l, r}, v, :ldir), do: {[v | l], r}
  def insert({l, r}, v, :endl), do: {l ++ [v], r}
  def insert({l, r}, v, :endr), do: {l, r ++ [v]}

  @doc """
  Insert a sequence of values to the left or right
  of the current focus, or at the beginning
  or end of the whole list.

  Whether it is inserted to the left or right
  does not affect the final content of the list,
  just the final position of the focus
  relative to the inserted sequence.

  Inserting an empty sequence does not change the underlying list.
  """
  @spec inserts(yazl(a), [a], direction() | ending()) :: yazl(a) when a: var
  def inserts(yazl, vals, dir \\ :rdir)

  def inserts(z, [], _), do: z
  def inserts(z, [v], dir), do: insert(z, v, dir)
  def inserts({l, r}, vs, :rdir), do: {l, vs ++ r}
  def inserts({l, r}, vs, :ldir), do: {Enum.reverse(vs, l), r}
  def inserts({l, r}, vs, :endr), do: {l, r ++ vs}
  def inserts({l, r}, vs, :endl), do: {l ++ Enum.reverse(vs), r}

  # ------
  # delete
  # ------

  @doc """
  Delete the value to the right or left of the focus.

  If the yazl is empty, or the focus is already
  at the beginning or end of a list, then return `:endr` or `:endl`.

  This is fast constant time O(1).
  """
  @spec delete(yazl(a), direction()) :: endable(yazl(a)) when a: var
  def delete(yazl, dir \\ :rdir)
  def delete({_, []}, :rdir), do: :endr
  def delete({[], _}, :ldir), do: :endl
  def delete({l, [_ | rt]}, :rdir), do: {l, rt}
  def delete({[_ | lt], r}, :ldir), do: {lt, r}

  @doc """
  Delete the indicated sublist.

  If the yazl is empty, return the empty yazl.

  For truncate right, the focus will be positioned after the
  last element of the left sublist.

  For truncate left, the focus will be positioned before the
  first element of the right sublist.

  This is fast constant time O(1).
  """
  @spec truncate(yazl(a), direction()) :: yazl(a) when a: var
  def truncate({l, _}, :rdir), do: {l, []}
  def truncate({_, r}, :ldir), do: {[], r}

  # ---------
  # functions
  # ---------

  @doc """
  Apply a map while leaving the focus unchanged.

  If the yazl is empty it will be unchanged.
  """
  @spec map(yazl(a), E.mapper(a, b)) :: yazl(b) when a: var, b: var
  def map({l, r}, mfun), do: {Enum.map(l, mfun), Enum.map(r, mfun)}
end
