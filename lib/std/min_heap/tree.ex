defmodule Exa.Std.MinHeap.Tree do
  @moduledoc """
  A minimum heap implemented using a complete binary tree.

  If there are multiple keys with the same value,
  their order will be by key (ascending).

  ## Complete Binary Tree

  We build a complete binary tree, 
  where each node has a data entry.

  Leaf nodes do not have any children. 

  Branch nodes have two children, 
  except there may be one branch node with just one child.
  We call the slots for children _left_ (first) and _right_ (second).

  There is a special case for the root, 
  which is completely empty for an empty tree.

  A _layer_ is a set of nodes at the same depth in the tree.

  A binary tree can be described using two 0-based integers:
  - depth: the number of ancestors, also the number of completed layers.
  - position: the number of previous siblings within the layer.

  A complete binary tree is filled by layer 
  i.e. _balanced_, but not totally binary.
  A new layer is only started when the previous layer is complete.
  According to our naming convention, 
  layers are filled from left-to-right.

  The _size_ of the tree is the total number of entries _N._

  The maximum depth of the whole tree is `O(logN).`

  ## Binary Address

  Navigation from the root to any entry in the tree
  can be represented as a sequence of left and right turns.
  If we assign left as `0`, and right as `1`,
  then any node can be addresed by a binary number.
  The number of binary digits will equal the layer index.
  Leading zeroes are significant.

  The empty binary indicates the root (if it exists).
  The first layer has addresses: `0` left and `1` right.
  The second layer has addresses: `00` `01` `10` `11`.

  ## Cursor

  A _cursor_ is the current location in the tree,
  where entries will be inserted or removed during deletion. 

  The cursor is the address of the _last_ entry in the tree,
  i.e. the last (rightmost) position in the last (deepest) layer.

  An inserted entry will be added after (right of) the cursor.
  The entry removed during deletion will be 
  taken from before (left of) the cursor.

  If the last layer is complete, then the deletion point 
  will be the last entry in that layer, and the insertion point
  will be the first position in the next (empty) layer.

  The critical observation for complete binary trees,
  is that the address of the current location
  can be _calculated_ from the size.
  The address can then be used to navigate 
  directly the current location in O(logN) steps.

  This means there is no need to use a more complex data structure
  that explicitly maintains the cursor location as a 
  structural property of the data representation
  (e.g. zipper or finger tree).

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

  Traversal down from root down to current location 
  follows the evaluation of the cursor bitstring 
  into left-right choices, while maintaining a 
  path of ancestors through the tree.
  [In zipper terminology, this is an _unzip_ operation.]

  Traversal from modified location (insert/delete)
  back up to the root will sew the two sides of the tree back together,
  making sure to swap entries to maintain the min-heap property.
  [In zipper terminology, this is an _zip_ operation.]

  Both traversals are O(logN) operations,
  so `push`, `pop` and `delete` are also O(logN).
  """

  import Bitwise
  alias Exa.Types, as: E

  defmodule MHTree do
    alias Exa.Types, as: E
    alias Exa.Std.MinHeap, as: MH

    # leaves are vk entries or empty marker
    @type vkleaf() :: :empty | MH.vktup()

    # left subtree cannot be empty (complete binary tree)
    @typep non_empty_vknode() :: MH.vktup() | vkbranch()

    # root or right subtree may be empty
    @typep vknode() :: :empty | non_empty_vknode()

    # node has a data entry and one or two children
    # which can be raw entries or subtrees
    # but cannot be left-entry right-subtree
    # if it is left-subtree right-entry
    # then the subtree must contain 1 or 2 leaf entries
    # no need for tagged tuple here because
    # 3-tuple node matches differently from 2-tuple entry
    @typep vkbranch() :: {MH.vktup(), non_empty_vknode(), vknode()}

    # the root has the same properties as a right component
    @typep vkroot() :: vknode()

    defstruct root: :empty,
              size: 0

    @type t :: %__MODULE__{
            root: vkroot(),
            size: E.count()
          }

    # cursor types

    @type cnode() ::
            MH.vkleaf()
            | {MH.vktup(), :l, vknode()}
            | {MH.vktup(), non_empty_vknode(), :r}

    @type cursor() :: [cnode()]
  end

  # O(1)
  @doc "Create an empty heap."
  def new(), do: %MHTree{}

  # testing only
  def create(root, size), do: %MHTree{root: root, size: size}

  # --------
  # protocol
  # --------

  defimpl Exa.Std.MinHeap, for: MHTree do
    # O(1)
    def size(%MHTree{size: size}), do: size

    # O(n)
    def has_key?(%MHTree{root: root}, key), do: find(root, key) != :error

    # O(n)
    def get(%MHTree{root: root}, key, default \\ nil) do
      case find(root, key) do
        {:ok, v} -> v
        :error -> default
      end
    end

    # O(n)
    def fetch!(%MHTree{root: root}, key) do
      case find(root, key) do
        {:ok, v} -> v
        :error -> raise(ArgumentError, message: "Heap missing key '#{key}'")
      end
    end

    # O(n)
    def to_list(%MHTree{root: root}), do: do_list([], root)

    @spec do_list([MH.kvtup()], MHTree.vknode()) :: [MH.kvtup()]
    defp do_list(acc, {{v, k}, l, r}), do: [{k, v} | acc] |> do_list(l) |> do_list(r)
    defp do_list(acc, {v, k}), do: [{k, v} | acc]
    defp do_list(acc, :empty), do: acc

    # O(n)
    def to_map(%MHTree{root: root}), do: do_map(%{}, root)

    @spec do_map(MH.kvmap(), MHTree.vknode()) :: MH.kvmap()
    defp do_map(acc, {{v, k}, l, r}), do: Map.put(acc, k, v) |> do_map(l) |> do_map(r)
    defp do_map(acc, {v, k}), do: Map.put(acc, k, v)
    defp do_map(acc, :empty), do: acc

    # O(NlogN) - slow but easy
    def delete(%MHTree{root: root}, key), do: do_del(%MHTree{}, root, key)

    @spec do_del(MHTree.t(), MHTree.vknode(), MH.key()) :: MHTree.t()
    defp do_del(acc, {{_v, key}, l, r}, key), do: acc |> do_del(l, key) |> do_del(r, key)
    defp do_del(acc, {{v, k}, l, r}, key), do: add(acc, k, v) |> do_del(l, key) |> do_del(r, key)
    defp do_del(acc, {_v, key}, key), do: acc
    defp do_del(acc, {v, k}, _key), do: add(acc, k, v)
    defp do_del(acc, :empty, _key), do: acc

    # O(1)
    def peek(%MHTree{root: root}), do: do_peek(root)

    @spec do_peek(MH.kvnode()) :: MH.kvleaf()
    defp do_peek({{v, k}, _, _}), do: {k, v}
    defp do_peek({v, k}), do: {k, v}
    defp do_peek(:empty), do: :empty

    # O(logN)

    def add(%MHTree{root: :empty}, k, v), do: %MHTree{root: {v, k}, size: 1}

    def add(%MHTree{root: root, size: n}, k, v) do
      # note - does not raise on existing key
      m = n + 1
      new_root = root |> unzip_addr(m) |> izip({v, k})
      %MHTree{root: new_root, size: m}
    end

    # O(N)

    def update(%MHTree{root: :empty}, k, v), do: %MHTree{root: {v, k}, size: 1}

    def update(%MHTree{root: root, size: n}, k, v) do
      new_root =
        case unzip_key(root, k) do
          :not_found -> raise(ArgumentError, message: "Heap missing key '#{k}'")
          {{_, ^k}, path} -> dzip(path, {v, k})
          {{{u, ^k}, l, r}, path} when v < u -> dzip(path, {{v, k}, l, r})
          {{{_, ^k}, l, r}, path} -> dzip(path, heapify({{v, k}, l, r}))
        end

      %MHTree{root: new_root, size: n}
    end

    # O(logN)
    def pop(%MHTree{root: :empty, size: 0}), do: :empty

    def pop(%MHTree{root: {v, k}, size: 1}),
      do: {{k, v}, %MHTree{}}

    def pop(%MHTree{root: {{v, k}, vk, :empty}, size: 2}),
      do: {{k, v}, %MHTree{root: vk, size: 1}}

    def pop(%MHTree{root: root, size: n}) do
      # build cursor down to delete location and isolate leaf entry
      [vkdel | dpath] = unzip_addr(root, n)
      # size >= 3 so always a branch node after deletion
      {{vmin, kmin}, l, r} = dzip(dpath)
      # substitute removed entry at root and bubble value down
      new_root = heapify({vkdel, l, r})
      {{kmin, vmin}, %MHTree{root: new_root, size: n - 1}}
    end

    # ----------
    # insert zip
    # ----------

    # zip upwards along a cursor path after insertion
    # bubble min values to the top
    @spec izip(MHTree.cursor(), MH.vknode()) :: MH.vkroot()

    # insert new entry into leaf
    defp izip([{vk1, {_, _} = l, :r} | p], vk) when vk < vk1, do: izip(p, {vk, l, vk1})
    defp izip([{vk1, {_, _} = l, :r} | p], vk), do: izip(p, {vk1, l, vk})
    defp izip([{_, _} = vk1 | p], vk) when vk < vk1, do: izip(p, {vk, vk1, :empty})
    defp izip([{_, _} = vk1 | p], vk), do: izip(p, {vk1, vk, :empty})

    # main branch node traversal
    defp izip([{vk1, l1, :r} | p], {vk, l, r}) when vk < vk1, do: izip(p, {vk, l1, {vk1, l, r}})
    defp izip([{vk1, l1, :r} | p], {_, _, _} = r1), do: izip(p, {vk1, l1, r1})
    defp izip([{vk1, :l, r1} | p], {vk, l, r}) when vk < vk1, do: izip(p, {vk, {vk1, l, r}, r1})
    defp izip([{vk1, :l, r1} | p], {_, _, _} = l1), do: izip(p, {vk1, l1, r1})

    # return new root
    defp izip([], root), do: root

    # ----------
    # delete zip
    # ----------

    # zip upwards along a cursor path after deletion
    # minimum property is implicitly preserved

    # first step makes a new leaf at the delete location
    @spec dzip(MHTree.cursor()) :: MH.vkroot()
    defp dzip([{vk1, {_, _} = vk2, :r} | dpath]), do: dzip(dpath, {vk1, vk2, :empty})
    defp dzip([{vk1, :l, :empty} | dpath]), do: dzip(dpath, vk1)

    # rebuild cursor over subtree
    @spec dzip(MHTree.cursor(), MHTree.vknode()) :: MH.vkroot()

    # neutral no-op merge
    defp dzip([{vk, l, :r} | p], sub), do: dzip(p, {vk, l, sub})
    defp dzip([{vk, :l, r} | p], sub), do: dzip(p, {vk, sub, r})

    # return new root
    defp dzip([], root), do: root

    # -------
    # heapify
    # -------

    # reorder a tree with a new root
    # to enforce the heap property that parent is minimum of children
    # traverse down while bubbling low values up

    @spec heapify(MHTree.vknode()) :: MHTree.vkroot()

    # general branch node

    defp heapify({vk, {vk1, _, _}, {vk2, _, _}} = vknode) when vk < vk1 and vk < vk2,
      do: vknode

    defp heapify({vk, {vk1, l1, r1}, {vk2, _, _} = r}) when vk1 < vk and vk1 < vk2,
      do: {vk1, heapify({vk, l1, r1}), r}

    defp heapify({vk, {_, _, _} = l, {vk2, l2, r2}}),
      do: {vk2, l, heapify({vk, l2, r2})}

    # full node and entry leaf

    defp heapify({vk, {vk1, _, _}, {_, _} = vk2} = vknode) when vk < vk1 and vk < vk2,
      do: vknode

    defp heapify({vk, {vk1, l1, r1}, {_, _} = vk2}) when vk1 < vk and vk1 < vk2,
      do: {vk1, heapify({vk, l1, r1}), vk2}

    defp heapify({vk, {_, _, _} = l, {_, _} = vk2}),
      do: {vk2, l, vk}

    # two entry leaves

    defp heapify({vk, {_, _} = vk1, {_, _} = vk2} = vknode) when vk < vk1 and vk < vk2,
      do: vknode

    defp heapify({vk, {_, _} = vk1, {_, _} = vk2}) when vk1 < vk and vk1 < vk2,
      do: {vk1, vk, vk2}

    defp heapify({vk, {_, _} = vk1, {_, _} = vk2}),
      do: {vk2, vk1, vk}

    # single entry leaf

    defp heapify({vk, {_, _} = vk1, :empty} = vknode) when vk < vk1, do: vknode
    defp heapify({vk, {_, _} = vk1, :empty}), do: {vk1, vk, :empty}

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
    @spec find(MHTree.vknode(), MH.key()) :: {:ok, MH.val()} | :error

    defp find({{v, key}, _l, _r}, key), do: {:ok, v}

    defp find({_, l, r}, key) do
      case find(l, key) do
        {:ok, _} = ans -> ans
        :error -> find(r, key)
      end
    end

    defp find({v, key}, key), do: {:ok, v}
    defp find(_, _), do: :error

    # ------------
    # unzip to key
    # ------------

    # traverse the whole tree to find a key
    # maintain and return a path cursor
    # and a subtree containing the target entry
    @spec unzip_key(MHTree.vkroot(), MH.key()) :: :not_found | {MHTree.vknode(), MHTree.cursor()}
    defp unzip_key(root, key), do: unzipk(root, key, [])

    @spec unzipk(MHTree.vknode(), MH.key(), MHTree.cursor()) ::
            :not_found | {MHTree.vknode(), MHTree.cursor()}

    defp unzipk({{_, key}, _l, _r} = sub, key, path), do: {sub, path}

    defp unzipk({vk, l, r}, key, path) do
      case unzipk(l, key, [{vk, :l, r} | path]) do
        :not_found -> unzipk(r, key, [{vk, l, :r} | path])
        {_, _} = ans -> ans
      end
    end

    defp unzipk({_, key} = sub, key, path), do: {sub, path}
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
end
