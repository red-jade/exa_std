defmodule Exa.Std.MinHeap.Tree do
  @moduledoc """
  A minimum heap implemented using a complete binary tree.

  If there are multiple keys with the same value,
  their order will be by key (ascending).

  Each node in the complete binary tree, 
  has a value-key data entry.

  The _size_ of the tree is the total number of entries _N._

  The maximum depth of the whole tree is `ceil(log₂N)` ~ `O(logN)`.

  The structure of the tree depends on insertion order,
  so trees constructed from the same values,
  but added in a different order,
  will not usually be strictly equal `==`.

  For an equlity comparison, convert `to_map/1`
  and compare the maps for equality.

  ## Complete Binary Tree

  A binary tree is one where branch nodes 
  typically have two children.
  However, a _complete_ binary tree is not a _total_ binary tree,
  because one branch node may have just one child.

  We call the slots for children _left_ (first) and _right_ (second).
  There are two special cases:
  - A branch node with just one child,
    has an `:empty` marker in the right slot.
  - An empty tree with have `:empty` root.

  Leaf nodes do not have any children. 
  A leaf node will just be a pure data entry

  ## Layers

  A _layer_ is a set of nodes at the same depth in the tree.

  A _complete_ binary tree is filled by layer 
  i.e. _balanced_, but not totally binary.
  According to our naming convention, 
  layers are filled from left-to-right.

  Each node in the tree can be described with two 0-based integers:
  - layer: the number of ancestors
  - position: the number of previous siblings within the layer

  So all layers are complete, except possibly the last layer,
  which may be complete or incomplete.
  A new layer is only started when the previous layer is complete.

  If the last layer is complete, every branch node 
  in the previous layer has exactly two children.
  The deletion point will be the last right child in the layer.
  The insertion point will be to start a new layer.

  If the last layer is incomplete, the boundary occurs at either:
  - a single branch node that has one left child and an empty right slot
  - a branch node with two children, followed by a leaf node with no children

  The deletion point will be either:
  - the left child of the partial branch node, 
    converting the branch to a leaf
  - the right child of the last complete branch node, 
    leaving an `:empty` right slot

  ## Binary Address

  Navigation from the root to any entry in the tree
  can be represented as a sequence of left and right turns.
  If we assign left as `0`, and right as `1`,
  then any node can be addresed by a binary number.
  Leading zeroes are significant.

  The number of binary digits will equal the layer.

  The binary address evaluates to the position in the layer. 

  The empty binary indicates the root (if it exists).

  The first layer has addresses: `0` left and `1` right.

  The second layer has addresses: `00` `01` `10` `11`.

  **The critical observation for complete binary trees,
  is that the binary address of the current location
  can be _calculated_ from the size.**

  ## Cursor

  A _cursor_ points to a current location within the tree,
  where entries will be inserted or removed. 

  A cursor is a sequence (list) of nodes,
  starting within the tree and ending at the root.
  A full cursor begins with a concrete target subtree branch or leaf node.
  All the remaining branch nodes in the cursor 
  have the left or right slot replaced by a turn marker: `:l` or `:r`.

  Note that a full cursor from a concrete head node up to the root,
  contains _all_ the information necessary to rebuild the whole tree. 

  **The binary address can be used to build a cursor  
  directly to the target location in `O(logN)` steps.**

  The deletion point is the node at the binary address
  calculated from the current size of the tree, `N`.
  The deletion cursor will truncate 
  the head term for the deleted data entry leaf node.

  The insertion point is the node at the binary address
  calculated from the future size of the tree, `N+1`.
  The insertion cursor will implicitly have the new 
  data entry leaf node as the head of the cursor.

  ## Zipper

  Operations using a cursor path are like a _Zipper_ (Huet, 1997).

  There are two styles of processing cursors within the tree:
  - _unzip_ : build a cursor downwards from root, 
    using left and right turns through branch nodes
  - _zip_ : consume a cursor by building a concrete subtree upwards, 
    until it becomes the new root 

  All _zip_ and _unzip_ operations on cursors are `O(logN)`. 

  ## Implementation

  The data structure for the tree contains:
  - root of the tree (empty, entry or branch node)
  - size of the tree

  A data entry is a `{value, key}` pair,
  so that the term order is the data order.
  The value is a number or `:inf` for the max value.
  Note that all numbers are less than atoms: `x < :inf`.

  The tree is represented as:
  - branch nodes are a 3-tuple of `{entry, left, right}`
  - leaf nodes are either `entry | :empty`

  A binary address is represented as a bitstring
  (sequence of binary digits).

  A full cursor is a list containing:
  - head: a concrete leaf or branch node
  - tail: path of branch nodes with one `:l` or `:r` turn marker

  There are several zipper operations using cursors:
  - unzip:
    - to target binary address for insert/delete
    - to target key (full tree traversal)
    - bubbling high values down the tree 
  - zip:
    - neutral zip that just rebuilds the tree from the cursor
    - delete target, make new leaf, then neutral zip
    - insert at target, make new leaf, then bubble low value up

  ### Operations

  Heap operations are implemented using unzip/zip cursors `O(logN)`,
  and full tree traversal for random access to a key `O(N)`.

  `add/3`:
  - unzip to binary address of insertion (after last entry)
  - zip insertion, bubble up new low value

  `update/3`:
  - unzip to find key (full traversal)
  - replace value of target key:
    - partial zip down, bubble new high value down into subtree
    - partial zip up, bubble the new low value up to root

  `pop/1`:
  - unzip to binary address of deletion (last entry)
  - retain removed leaf
  - zip deletion, neutral zip up
  - replace root node with removed node:
    - zip down, bubble the moved high value down

  `delete/2`:
  - unzip to binary address of deletion (last entry)
  - retain removed leaf
  - zip deletion, neutral zip up
  - unzip to find key (full traversal)
  - replace target node with removed leaf:
    - partial zip down, bubble the moved high value down into subtree
    - partial zip up, bubble the moved low value up to root

  `has_key?/1`, `get/3`, `fetch!`:
  - traverse to find key (full traversal)

  ### Complexity

  Building and navigating cursors are `O(logN)` operations.

  Functions `new/0`, `size/1` and `peek/1` are `O(1)`.

  Cursor traversals are `O(logN)`:
  `add/3`, `update/3` and `pop/1`.  

  All operations that require a full tree traversal are `O(N)`:
  `has_key?/1`, `get/3`, `delete/2`, `fetch!/2`, `to_list/1` and `to_map/1`.
  """

  import Bitwise

  alias Exa.Types, as: E

  alias Exa.Std.MinHeap

  defmodule MHTree do
    alias Exa.Types, as: E
    alias Exa.Std.MinHeap, as: MH

    # leaves are vk entries or empty marker
    @type vkleaf() :: :empty | MH.vktup()

    # left subtree cannot be empty (complete binary tree)
    @type non_empty_vknode() :: MH.vktup() | vkbranch()

    # root or right subtree may be empty
    @type vknode() :: :empty | non_empty_vknode()

    # node has a data entry and one or two children
    # which can be raw entries or subtrees
    # but cannot be left-entry right-subtree
    # if it is left-subtree right-entry
    # then the subtree must contain 1 or 2 leaf entries
    # no need for tagged tuple here because
    # 3-tuple node matches differently from 2-tuple entry
    @type vkbranch() :: {MH.vktup(), non_empty_vknode(), vknode()}

    # the root has the same properties as a right component
    @type vkroot() :: vknode()

    defstruct root: :empty,
              size: 0

    @type t :: %__MODULE__{
            root: vkroot(),
            size: E.count()
          }

    # cursor types ----------

    @type cnode() ::
            vkleaf()
            | {MH.vktup(), :l, vknode()}
            | {MH.vktup(), non_empty_vknode(), :r}

    # the head of a cursor must be a concrete node
    # the tail must contain branch nodes with l/r placeholders
    # cursors are not used for simple root: entry or empty
    @type cursor() :: [cnode()]
  end

  # O(1)
  @doc "Create an empty heap."
  def new(), do: %MHTree{}

  # O(NlogN)
  @doc "Create a heap from a key-value map."
  @spec new(MH.kvmap()) :: MHTree.t()
  def new(map) when is_map(map),
    do: Enum.reduce(map, %MHTree{}, fn {k, v}, mh -> MinHeap.add(mh, k, v) end)

  # --------
  # protocol
  # --------

  defimpl Exa.Std.MinHeap, for: MHTree do
    defguard is_val(v) when is_number(v) or v == :inf

    # O(1)
    def size(%MHTree{size: size}), do: size

    # O(N)
    def has_key?(%MHTree{root: root}, key), do: find(root, key) != :not_found

    # O(N)
    def get(%MHTree{root: root}, key, default \\ nil) do
      case find(root, key) do
        {:ok, v} -> v
        :not_found -> default
      end
    end

    # O(N)
    def fetch!(%MHTree{root: root}, key) do
      case find(root, key) do
        {:ok, v} -> v
        :not_found -> raise(ArgumentError, message: "Heap missing key '#{key}'")
      end
    end

    # O(N)
    def to_list(%MHTree{root: root}), do: do_list([], root)

    @spec do_list([MH.kvtup()], MHTree.vknode()) :: [MH.kvtup()]
    defp do_list(acc, {{v, k}, l, r}), do: [{k, v} | acc] |> do_list(l) |> do_list(r)
    defp do_list(acc, {v, k}), do: [{k, v} | acc]
    defp do_list(acc, :empty), do: acc

    # O(N)
    def to_map(%MHTree{root: root}), do: do_map(%{}, root)

    @spec do_map(MH.kvmap(), MHTree.vknode()) :: MH.kvmap()
    defp do_map(acc, {{v, k}, l, r}), do: Map.put(acc, k, v) |> do_map(l) |> do_map(r)
    defp do_map(acc, {v, k}), do: Map.put(acc, k, v)
    defp do_map(acc, :empty), do: acc

    # O(N)
    def keys(%MHTree{root: root}), do: do_keys([], root)

    @spec do_keys([MH.key()], MHTree.vknode()) :: [MH.key()]
    defp do_keys(acc, {{_, k}, l, r}), do: [k | acc] |> do_keys(l) |> do_keys(r)
    defp do_keys(acc, {_, k}), do: [k | acc]
    defp do_keys(acc, :empty), do: acc

    # O(N) 

    def delete(%MHTree{root: :empty, size: 0} = empty, _key), do: empty

    def delete(%MHTree{root: {_, key}, size: 1}, key), do: %MHTree{}
    def delete(%MHTree{root: {_, _}, size: 1} = heap, _key), do: heap

    def delete(%MHTree{root: root, size: n} = heap, key) do
      # build cursor down to remove location and isolate leaf entry
      [{_vdel, kdel} = vkdel | dpath] = unzip_addr(root, n)

      # zip back up to make new complete tree with deletion
      droot = dzip(dpath)

      # small 1/N chance the delete location is the target!
      # otherwise replace the delete target with the removed entry
      new_root = if kdel == key, do: droot, else: replace!(droot, key, vkdel)

      %{heap | root: new_root, size: n - 1}
    end

    # O(1)
    def peek(%MHTree{root: root}), do: do_peek(root)

    @spec do_peek(MH.kvnode()) :: MH.kvleaf()
    defp do_peek({{v, k}, _, _}), do: {k, v}
    defp do_peek({v, k}), do: {k, v}
    defp do_peek(:empty), do: :empty

    # O(logN)

    def add(%MHTree{root: :empty} = heap, k, v) when is_val(v),
      do: %{heap | root: {v, k}, size: 1}

    def add(%MHTree{root: root, size: n} = heap, k, v) when is_val(v) do
      # note - does not raise on existing key
      m = n + 1
      new_root = root |> unzip_addr(m) |> izip({v, k})
      %{heap | root: new_root, size: m}
    end

    # O(N)
    def update(%MHTree{root: root} = heap, k, v) when is_val(v) do
      %{heap | root: replace!(root, k, {v, k})}
    end

    # O(logN)
    def pop(%MHTree{root: :empty, size: 0}), do: :empty

    def pop(%MHTree{root: {v, k}, size: 1}), do: {{k, v}, %MHTree{}}

    def pop(%MHTree{root: {{v, k}, vk, :empty}, size: 2} = heap),
      do: {{k, v}, %{heap | root: vk, size: 1}}

    def pop(%MHTree{root: root, size: n} = heap) do
      # build cursor down to delete location and isolate leaf entry
      [vkdel | dpath] = unzip_addr(root, n)

      # zip back up to make new complete tree
      # size >= 3 so always a branch node after deletion
      {{vmin, kmin}, l, r} = dzip(dpath)

      # substitute removed entry at root and bubble value down
      {mpath, sub} = unzip_min({vkdel, l, r})

      # no-op zip back up again
      new_root = zip(mpath, sub)

      {{kmin, vmin}, %{heap | root: new_root, size: n - 1}}
    end

    # -------
    # replace
    # -------

    # find a target key and replace the full entry 
    # then bubble the new entry down/up to make the new root
    @spec replace!(MH.vkroot(), MH.key(), MH.vktup()) :: MH.vkroot()
    defp replace!(root, k, vknew) do
      case unzip_key(root, k) do
        :not_found -> raise(ArgumentError, message: "Heap missing key '#{k}'")
        [^vknew | _] -> root
        [{^vknew, _, _} | _] -> root
        kpath -> repl(kpath, vknew)
      end
    end

    # replace an entry at a cursor location 
    # then bubble the new value down/up to make the new root
    @spec repl(MHTree.cursor(), MH.vktup()) :: MH.vkroot()

    # found in a leaf node - just bubble up
    defp repl([{_, _} | path], vk), do: izip(path, vk)

    # new low value maintains heap property in the subtree - just bubble up
    defp repl([{{u, _}, l, r} | path], {v, _} = vk) when v < u, do: izip(path, {vk, l, r})

    # new high value must be bubbled down into subtree
    defp repl([{{_, _}, l, r} | path], vk) do
      {mpath, sub} = unzipm({vk, l, r}, path)
      izip(mpath, sub)
    end

    # ----------
    # insert zip
    # ----------

    # zip upwards along a cursor path after insertion
    # bubble min values to the top
    @spec izip(MHTree.cursor(), MH.vknode()) :: MH.vkroot()

    # main branch node traversal
    defp izip([{vk1, l1, :r} | p], {vk, l, r}) when vk < vk1, do: izip(p, {vk, l1, {vk1, l, r}})
    defp izip([{vk1, l1, :r} | p], {_, _, _} = r1), do: izip(p, {vk1, l1, r1})
    defp izip([{vk1, :l, r1} | p], {vk, l, r}) when vk < vk1, do: izip(p, {vk, {vk1, l, r}, r1})
    defp izip([{vk1, :l, r1} | p], {_, _, _} = l1), do: izip(p, {vk1, l1, r1})

    # insert new entry into parent of leaves
    # note {_, l, :r} may have l={_,_} or {_,_,:empty}
    defp izip([{vk1, :l, {_, _} = r} | p], {_, _} = vk) when vk < vk1, do: izip(p, {vk, vk1, r})
    defp izip([{vk1, :l, {_, _} = r} | p], {_, _} = vk), do: izip(p, {vk1, vk, r})
    defp izip([{vk1, l, :r} | p], {_, _} = vk) when vk < vk1, do: izip(p, {vk, l, vk1})
    defp izip([{vk1, l, :r} | p], {_, _} = vk), do: izip(p, {vk1, l, vk})

    # insert new entry into leaf
    defp izip([{_, _} = vk1 | p], {_, _} = vk) when vk < vk1, do: izip(p, {vk, vk1, :empty})
    defp izip([{_, _} = vk1 | p], {_, _} = vk), do: izip(p, {vk1, vk, :empty})
    defp izip([{vk1, :l, :empty} | p], {_, _} = vk) when vk < vk1, do: izip(p, {vk, vk1, :empty})
    defp izip([{vk1, :l, :empty} | p], {_, _} = vk), do: izip(p, {vk1, vk, :empty})

    # return new root
    defp izip([], root), do: root

    # ----------
    # delete zip
    # ----------

    # zip upwards along a cursor path after deletion
    # minimum property is implicitly preserved
    # does not accept special case of empty or single entry root
    # first step makes a new leaf at the delete location, then no-op zip
    @spec dzip(MHTree.cursor()) :: MH.vkroot()
    defp dzip([{vk1, {_, _} = vk2, :r} | dpath]), do: zip(dpath, {vk1, vk2, :empty})
    defp dzip([{vk1, :l, {_, _} = vk2} | dpath]), do: zip(dpath, {vk1, vk2, :empty})
    defp dzip([{vk1, :l, :empty} | dpath]), do: zip(dpath, vk1)

    # --------
    # pure zip
    # --------

    # rebuild cursor over subtree
    # neutral no-op merge
    @spec zip(MHTree.cursor(), MHTree.vknode()) :: MH.vkroot()
    defp zip([{vk, l, :r} | p], sub), do: zip(p, {vk, l, sub})
    defp zip([{vk, :l, r} | p], sub), do: zip(p, {vk, sub, r})
    defp zip([], root), do: root

    # ---------
    # unzip min
    # ---------

    # reorder tree with a new root to enforce 
    # heap property that parent is minimum of children
    # rebalancing occurs down a single cursor path, so it is an unzip

    @spec unzip_min(MHTree.vkroot()) :: {MHTree.cursor(), MHTree.vknode()}
    defp unzip_min(root), do: unzipm(root, [])

    # tail-recursive traversal down the tree
    # while bubbling lower values up
    # stop when target node satisfies heap property
    # return cursor to the valid subtree at that point
    @spec unzipm(MHTree.vknode(), MHTree.cursor()) :: {MHTree.cursor(), MHTree.vknode()}

    # general branch node

    defp unzipm({vk, {vk1, _, _}, {vk2, _, _}} = vknode, p) when vk < vk1 and vk < vk2,
      do: {p, vknode}

    defp unzipm({vk, {vk1, l1, r1}, {vk2, _, _} = r}, p) when vk1 < vk and vk1 < vk2,
      do: unzipm({vk, l1, r1}, [{vk1, :l, r} | p])

    defp unzipm({vk, {_, _, _} = l, {vk2, l2, r2}}, p),
      do: unzipm({vk, l2, r2}, [{vk2, l, :r} | p])

    # full node and entry leaf

    defp unzipm({vk, {vk1, _, _}, {_, _} = vk2} = vknode, p) when vk < vk1 and vk < vk2,
      do: {p, vknode}

    defp unzipm({vk, {vk1, l1, r1}, {_, _} = vk2}, p) when vk1 < vk and vk1 < vk2,
      do: unzipm({vk, l1, r1}, [{vk1, :l, vk2} | p])

    defp unzipm({vk, {_, _, _} = l, {_, _} = vk2}, p),
      do: {p, {vk2, l, vk}}

    # two entry leaves

    defp unzipm({vk, {_, _} = vk1, {_, _} = vk2} = vknode, p) when vk < vk1 and vk < vk2,
      do: {p, vknode}

    defp unzipm({vk, {_, _} = vk1, {_, _} = vk2}, p) when vk1 < vk and vk1 < vk2,
      do: {p, {vk1, vk, vk2}}

    defp unzipm({vk, {_, _} = vk1, {_, _} = vk2}, p),
      do: {p, {vk2, vk1, vk}}

    # single entry leaf

    defp unzipm({vk, {_, _} = vk1, :empty} = vknode, p) when vk < vk1, do: {p, vknode}
    defp unzipm({vk, {_, _} = vk1, :empty}, p), do: {p, {vk1, vk, :empty}}

    # ----------------
    # unzip to address
    # ----------------

    # build a cursor path down towards a bit address
    # bits convert into turns marked with placeholders :l and :r
    @spec unzip_addr(MHTree.vkroot(), E.count()) :: MHTree.cursor()
    defp unzip_addr(root, n), do: unzipa(root, addr(n), [])

    @spec unzipa(MHTree.vknode(), E.bits(), MHTree.cursor()) :: MHTree.cursor()
    defp unzipa({e, l, r}, <<0::1, b::bits>>, p), do: unzipa(l, b, [{e, :l, r} | p])
    defp unzipa({e, l, r}, <<1::1, b::bits>>, p), do: unzipa(r, b, [{e, l, :r} | p])
    defp unzipa({_, _} = kv, _b, p), do: [kv | p]
    defp unzipa(:empty, _b, p), do: p

    # --------
    # find key
    # --------

    # traverse the whole tree to find a key
    # return the value, or error if not found
    @spec find(MHTree.vknode(), MH.key()) :: {:ok, MH.val()} | :not_found

    defp find({{v, key}, _l, _r}, key), do: {:ok, v}

    defp find({_, l, r}, key) do
      case find(l, key) do
        {:ok, _} = ans -> ans
        :not_found -> find(r, key)
      end
    end

    defp find({v, key}, key), do: {:ok, v}
    defp find(_, _), do: :not_found

    # ------------
    # unzip to key
    # ------------

    # traverse the whole tree to find a key
    # maintain and return a path cursor
    # with subtree containing the target entry at the head
    @spec unzip_key(MHTree.vkroot(), MH.key()) :: :not_found | MHTree.cursor()
    defp unzip_key(root, key), do: unzipk(root, key, [])

    @spec unzipk(MHTree.vknode(), MH.key(), MHTree.cursor()) :: :not_found | MHTree.cursor()

    defp unzipk({{_, key}, _l, _r} = sub, key, path), do: [sub | path]

    defp unzipk({vk, l, r}, key, path) do
      case unzipk(l, key, [{vk, :l, r} | path]) do
        :not_found -> unzipk(r, key, [{vk, l, :r} | path])
        new_path -> new_path
      end
    end

    defp unzipk({_, key} = sub, key, path), do: [sub | path]

    defp unzipk(_, _, _), do: :not_found

    # -------
    # address
    # -------

    # calculate the bitstring address of the last leaf node
    # bits are binary encoding of left (0) and right (0) turns
    @spec addr(E.count()) :: E.bits()
    defp addr(n) when n > 0 do
      layer = n |> :math.log2() |> floor()
      position = n - (1 <<< layer)
      Exa.Binary.from_uint(position, layer)
    end
  end

  # -------------
  # validate tree
  # -------------

  defguard is_val(v) when is_number(v) or v == :inf

  # verify that a tree satisfies the heap property:
  # - every value is number or :inf 
  # - heap property
  #   - parent value less than children
  # - complete binary tree
  #   - structure of branches and leaves is correct
  #   - leaves follow correct layer pattern
  #
  # raise error for failed validation
  # otherwise, return the heap argument unchanged

  @spec validate!(MHTree.t()) :: MHTree.t()

  def validate!(%MHTree{root: :empty, size: 0} = heap), do: heap

  def validate!(%MHTree{root: {v, _}, size: 1} = heap) when is_val(v), do: heap

  def validate!(%MHTree{root: {_, _, _} = root, size: n} = heap) do
    keys = Exa.Std.MinHeap.keys(heap)

    # size is correct  
    true = length(keys) == n

    # no repeated keys 
    true = Exa.List.unique?(keys)

    # basic structure is correct
    true = is_root(root)

    # validate correct sequence of leaves and depths

    # max depth (0-based layer) of leaves
    dmax = n |> :math.log2() |> floor()
    # number of max depth entries
    #      n -  2  ^  dmax  + 1
    nult = n - (1 <<< dmax) + 1
    # number of empty leaves as padding to even 
    # if nult is even (0) or odd (1)
    nemp = nult &&& 0x01
    # remaining leaves in previous layer
    #         2 ^ (dmax - 1)  -  (nult + nemp)/2
    npen = (1 <<< (dmax - 1)) - ((nult + nemp) >>> 1)

    leaves = [] |> leaves(0, root) |> Enum.reverse()

    true = length(leaves) == nult + nemp + npen

    rem =
      leaves
      |> entries(dmax, nult)
      |> empties(dmax, nemp)
      |> entries(dmax - 1, npen)

    true = rem == []

    heap
  end

  # traverse tree enforce heap property and collect {leaf,depth} sequence

  defp leaves(leaves, d, {{v, _} = vk, l, r}) when is_val(v) do
    # min heap property
    true = vk < val(l)
    true = vk < val(r)
    d = d + 1
    leaves |> leaves(d, l) |> leaves(d, r)
  end

  defp leaves(leaves, d, {v, _} = vk) when is_val(v), do: [{vk, d} | leaves]
  defp leaves(leaves, d, :empty), do: [{:empty, d} | leaves]

  # consume leaf entries at fixed depth
  defp entries(ls, _d, 0), do: ls
  defp entries([{{_, _}, d} | ls], d, n), do: entries(ls, d, n - 1)

  # consume empty leaf at given depth
  defp empties(ls, _d, 0), do: ls
  defp empties([{:empty, d} | ls], d, 1), do: ls

  # root structure
  defp is_root(:empty), do: true
  defp is_root({_, _}), do: true
  defp is_root({{_, _}, {_, _}, :empty}), do: true
  defp is_root({{_, _}, {_, _}, {_, _}}), do: true
  defp is_root(root), do: is_branch(root)

  # branch structure
  defp is_branch({{_, _}, {{_, _}, {_, _}, {_, _}}, {_, _}}), do: true
  defp is_branch({{_, _}, {{_, _}, {_, _}, {_, _}}, {{_, _}, {_, _}, :empty}}), do: true
  defp is_branch({{_, _}, {{_, _}, {_, _}, :empty}, {_, _}}), do: true
  defp is_branch({{_, _}, {_, _}, {_, _}}), do: true
  defp is_branch({{_, _}, {_, _, _} = l, {_, _, _} = r}), do: is_branch(l) and is_branch(r)

  # get value of node
  defp val({vk, _l, _r}), do: vk
  defp val({_, _} = vk), do: vk
  defp val(:empty), do: {:inf, :inf}
end
