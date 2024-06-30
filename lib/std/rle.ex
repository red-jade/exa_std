defmodule Exa.Std.Rle do
  @moduledoc """
  Run Length Encoded (RLE) list.

  An RLE is a list containing a sequence of:
  - raw elements
  - tuples containing a value and a repeat count. 

  The list can be any sequence of terms.
  Elixir (Erlang) define equality for all values.

  The head of the rle is always kept  
  as a single value for pattern matching,
  even if it is followed by repeats.

  Some list functions are also valid for RLEs,
  for example, `Kernel.hd` and `Enum.reverse`.
  Others are not valid for RLEs,
  such as, `Kernel.tl` (use `Rle.next`) 
  and `Kernel.length` (use `Rle.size`).
  """
  require Logger
  import Exa.Types
  alias Exa.Types, as: E

  # -----
  # types
  # -----

  @typedoc """
  A run length element.

  The count is always greater than 1.

  The `:rle` tag is necessary to distinguish it from input data."
  """
  @type run() :: {:rle, any(), E.count2()}
  defguard is_run(r) when is_tag_tuple(r, 3, :rle)

  @typedoc "A run length encoded list."
  @type rle() :: [any() | run()]
  defguard is_rle(rle) when is_list(rle)

  # -----------
  # constructor
  # -----------

  @doc "Create new RLE from an existing list."
  @spec new(list()) :: rle()
  def new(xs \\ [])
  def new([]), do: []
  def new([_] = xs), do: xs
  def new([_, _] = xs), do: xs
  def new([x | xs]), do: encode(xs, 1, [x])

  # the head of the input list is already counted 
  defp encode([x], 1, rle), do: Enum.reverse([x | rle])
  defp encode([x], n, rle), do: Enum.reverse([{:rle, x, n} | rle])
  defp encode([x | [x | _] = xs], n, rle), do: encode(xs, n + 1, rle)
  defp encode([x | xs], 1, rle), do: encode(xs, 1, [x | rle])
  defp encode([x | xs], n, rle), do: encode(xs, 1, [{:rle, x, n} | rle])

  @doc "Convert the RLE to a list."
  @spec to_list(rle()) :: list()
  def to_list([] = xs), do: xs
  def to_list([_] = xs), do: xs
  def to_list([_, x] = xs) when not is_run(x), do: xs

  def to_list(rle) when is_rle(rle) do
    Enum.reduce(Enum.reverse(rle), [], fn
      {:rle, x, n}, out -> dup(x, n, out)
      x, out -> [x | out]
    end)
  end

  defp dup(_, 0, out), do: out
  defp dup(x, n, out), do: dup(x, n - 1, [x | out])

  # ---------
  # accessors
  # ---------

  @doc "Get the total length of the RLE."
  @spec size(rle()) :: E.count()
  def size(rle) when is_rle(rle) do
    Enum.reduce(rle, 0, fn
      {:rle, _, k}, n -> n + k
      _, n -> n + 1
    end)
  end

  @doc """
  Get the element at 0-based position.
  Fails if the requested index exceeds the size of the RLE. 
  """
  @spec at(rle(), E.count()) :: any()
  def at(rle, n) when is_rle(rle) and is_count(n), do: do_at(rle, n)

  defp do_at([{:rle, x, k} | _], n) when k > n, do: x
  defp do_at([x | _], 0), do: x
  defp do_at([{:rle, _, k} | rle], n), do: do_at(rle, n - k)
  defp do_at([_ | rle], n), do: do_at(rle, n - 1)

  defp do_at([], _) do
    msg = "Index out of range"
    Logger.error(msg)
    raise ArgumentError, message: msg
  end

  @doc "Sum the RLE, assuming all elements are numbers."
  @spec sum(rle()) :: number()
  def sum([i | rle]), do: do_sum(rle, i)

  @spec do_sum(rle(), number()) :: number()
  defp do_sum([{:rle, x, n} | rle], sum) when is_number(x), do: do_sum(rle, sum + x * n)
  defp do_sum([x | rle], sum) when is_number(x), do: do_sum(rle, sum + x)
  defp do_sum([], sum), do: sum

  @doc "Minimum of the RLE, assuming all elements are numbers."
  @spec minimum(rle()) :: number()
  def minimum([i | rle]), do: do_min(rle, i)

  @spec do_min(rle(), number()) :: number()
  defp do_min([{:rle, x, _} | rle], min) when is_number(x), do: do_min(rle, min(min, x))
  defp do_min([x | rle], min) when is_number(x), do: do_min(rle, min(min, x))
  defp do_min([], min), do: min

  @doc "Maximum of the RLE, assuming all elements are numbers."
  @spec maximum(rle()) :: number()
  def maximum([i | rle]), do: do_max(rle, i)

  @spec do_max(rle(), number()) :: number()
  defp do_max([{:rle, x, _} | rle], max) when is_number(x), do: do_max(rle, max(max, x))
  defp do_max([x | rle], max) when is_number(x), do: do_max(rle, max(max, x))
  defp do_max([], max), do: max

  # ------
  # update
  # ------

  @doc """
  Get the tail of the RLE. 
  Advance the RLE ignoring the head element.
  Fails for an empty RLE.
  """
  @spec next(rle()) :: rle()
  def next([_]), do: []
  def next([_, {:rle, y, 2} | rle]), do: [y, y | rle]
  def next([_, {:rle, y, n} | rle]) when n > 2, do: [y, {:rle, y, n - 1} | rle]
  def next([_, y | rle]), do: [y | rle]

  @doc """
  Take a plain list from the head of the RLE 
  and return the tail continuation as an RLE.

  If the requested prefix is longer than the RLE input,
  the whole list is returned with an empty RLE.
  """
  @spec take(rle(), E.count1()) :: {list(), rle()}
  def take(rle, n \\ 1) when is_rle(rle) and is_count1(n), do: do_take(rle, n, [])

  defp do_take(rle, 0, head), do: {Enum.reverse(head), rle}
  defp do_take([], _, head), do: {Enum.reverse(head), []}
  defp do_take([x | _] = rle, n, head), do: do_take(next(rle), n - 1, [x | head])

  # TODO - delete, insert
end
