defmodule Exa.Std.Tidal do
  @moduledoc """
  Manage completeness of observed values 
  taken from a monotonic increasing integer sequence. 

  A monotonic increasing positive integer value starts at 1.
  Observations of the value have some random delays and jitter.
  So some observed values arrive out-of-order.

  The state of the observed sequence is characterized by:

  - Low Water Mark (LWM): 
    The end of a complete contiguous sequence of observed values starting at 1.

  - High Water Mark (HWM): 
    The highest currently observed value.
    Either equal to the LWM, or greater than LWM+1.

  - Between the LWM and HWM, 
    there is a partial set of observations, with missing values.
    In particular, LWM+1 is the lowest value that has not been observed.

  When a new value is observed, 
  it will satisfy one or more of these conditions:
  - above the HWM, so increase the HWM;
  - between LWM+1 and HWM, so add to the set
  - LWM+1 extends the contiguous observed range,
    increases the LWM, and possibly triggers consuming an 
    ascending sequence from the set, perhaps up to the HWM

  """
  import Exa.Types

  # ---------
  # constants 
  # ---------

  # Range object with no values
  @empty_range 0..1//-1

  # -----
  # types 
  # -----

  @typedoc "A monotonic ID counter."
  @type id() :: pos_integer()
  defguard is_id(id) when is_pos_int(id)

  @typedoc "A watermark that may be 0 or an id()."
  @type wm() :: 0 | id()
  defguard is_wm(wm) when is_nonneg_int(wm)

  @typedoc """
  A tidal data structure, with LWM, HWM and 
  a set of observed ids between the LWM and HWM.

  The total range of the id is divided into segments,
  some of which may be empty or coincident:
  - 1..LWM the contiguous range that has been observed
  - LWM+1 the lowest value that has not been observed
  - LWM+2..HWM-1 some (possibly empty) subset of this range has been observed
  - HWM the highest observed value

  The LWM is 0 or an id. 
  The HWM is 0 or an id.
  The HWM is greater than or equal to the LWM,
  but never equal to LWM + 1.

  If LWM == HWM == 0, then the set is empty,
  and the whole tidal is empty.

  If HWM == LWM, the set is empty,
  and the tidal represents a complete range 1..LWM.

  Otherwise:
  - there is always a gap above the LWM, so HWM > LWM + 1;
  - set contains integers from the range (LWM+2)..HWM;
  - the value LWM+1 is never in the set;
  - the value of the HWM is always in the set;
  - the size of the set, n, obeys 1 <= n <= HWM - LWM - 1 
  """
  @type tidal() :: {:tidal, wm(), wm(), MapSet.t()}
  defguard is_tidal(t)
           when is_tag_tuple(t, 4, :tidal) and
                  is_wm(elem(t, 1)) and
                  is_wm(elem(t, 2)) and
                  is_struct(elem(t, 3), MapSet)

  # -----------------
  # public functions
  # -----------------

  @doc "Create a new empty tidal."
  @spec new() :: tidal()
  def new(), do: {:tidal, 0, 0, MapSet.new()}

  @doc "Create a new tidal starting at given lwm/hwm."
  @spec new(wm()) :: tidal()
  def new(wm) when is_wm(wm), do: {:tidal, wm, wm, MapSet.new()}

  @doc "Create a new tidal with explicit list of values."
  @spec from_list([id()]) :: tidal()
  def from_list(ids) when is_list(ids) do
    ids |> Enum.sort() |> Enum.reduce(new(), fn i, t -> put(t, i) end)
  end

  @doc """
  Convert to a sorted ascending list.
  """
  @spec to_list(tidal()) :: [id()]
  def to_list({:tidal, 0, 0, _}), do: []

  def to_list({:tidal, 0, _hwm, ids}) do
    ids |> MapSet.to_list() |> Enum.sort()
  end

  def to_list({:tidal, lwm, _hwm, ids}) when lwm > 0 do
    Range.to_list(1..lwm) ++ (ids |> MapSet.to_list() |> Enum.sort())
  end

  @doc "Get the LWM."
  @spec lwm(tidal()) :: wm()
  def lwm({:tidal, lwm, _hwm, _ids}), do: lwm

  @doc "Get the HWM."
  @spec hwm(tidal()) :: wm()
  def hwm({:tidal, _lwm, hwm, _ids}), do: hwm

  @doc """
  Export as a range and an ascending list of extra values.
  If the tidal is empty, then the output range and list are both empty.
  """
  @spec to_range_list(tidal()) :: {Range.t(), [id()]}

  def to_range_list({:tidal, 0, 0, _empty}), do: {@empty_range, []}

  def to_range_list({:tidal, wm, wm, _empty}) when wm > 0, do: {1..wm, []}

  def to_range_list({:tidal, 0, hwm, ids}) when hwm > 0 do
    {@empty_range, ids |> MapSet.to_list() |> Enum.sort()}
  end

  def to_range_list({:tidal, lwm, hwm, ids}) when hwm > 0 do
    {1..lwm, ids |> MapSet.to_list() |> Enum.sort()}
  end

  @doc """
  Test if a tidal is a non-empty continuous sequence.
  If `true`, then LWM == HWM == size, 
  the ids set is empty,
  and the values are the range 1..HWM.
  """
  @spec complete?(tidal()) :: bool()
  def complete?({:tidal, lwm, hwm, _empty}), do: lwm == hwm and hwm > 0

  @doc "Test if the tidal is empty (size 0)."
  @spec empty?(tidal()) :: bool()
  def empty?({:tidal, 0, 0, _empty}), do: true
  def empty?({:tidal, wm, wm, _ids}) when wm > 0, do: false

  @doc """
  Get the size of the tidal, 
  which is the total count of values.
  """
  @spec size(tidal()) :: non_neg_integer()
  def size({:tidal, 0, 0, _empty}), do: 0
  def size({:tidal, lwm, _hwm, ids}), do: lwm + MapSet.size(ids)

  @doc "Test if an id value is in the tidal."
  @spec member?(tidal(), id()) :: bool()

  def member?({:tidal, 0, 0, _empty}, i) when is_id(i), do: false

  def member?({:tidal, lwm, _hwm, ids}, i) when is_id(i) do
    i <= lwm or MapSet.member?(ids, i)
  end

  @doc """
  Advance a new id to the tidal. 

  Add the id and also return the range 
  that the LWM has advanced (may be empty).
  This range is the sequence that has been added
  to the previous contiguous range.
  If the client is re-ordering, 
  then it is the range of new data 
  that can now be emitted
  to bring the stream up to date.

  It is illegal to advance by an existing member.
  """
  @spec advance(tidal(), id()) :: {tidal(), Range.t()} | {:duplicate, id(), tidal(), Range.t()}
  def advance(tidal, i) when is_tidal(tidal) and is_id(i) do
    if member?(tidal, i) do
      {:duplicate, i, tidal, @empty_range}
    else
      do_advance(tidal, i)
    end
  end

  @spec do_advance(tidal(), id()) :: {tidal(), Range.t()}

  defp do_advance({:tidal, 0, _, _} = tidal, i) when is_tidal(tidal) and is_id(i) do
    {:tidal, new_lwm, _, _} = new_tidal = put(tidal, i)

    {
      new_tidal,
      if(new_lwm == 0, do: @empty_range, else: 1..1)
    }
  end

  defp do_advance({:tidal, lwm, _, _} = tidal, i) when is_tidal(tidal) and is_id(i) do
    {:tidal, new_lwm, _, _} = new_tidal = put(tidal, i)

    {
      new_tidal,
      if(lwm == new_lwm, do: @empty_range, else: (lwm + 1)..new_lwm)
    }
  end

  @doc """
  Add a new id to the tidal.

  If the new id is already in the tidal,
  then return a duplicate error with the id 
  and the unchanged tidal.
  Otherwise just return the updated tidal.
  """
  @spec put(tidal(), id()) :: tidal() | {:duplicate, id(), tidal()}
  def put(tidal, i) when is_tidal(tidal) and is_id(i) do
    if member?(tidal, i) do
      {:duplicate, i, tidal}
    else
      do_put(tidal, i)
    end
  end

  defp do_put({:tidal, wm, wm, empty}, i) when i == wm + 1, do: {:tidal, i, i, empty}
  defp do_put({:tidal, wm, wm, empty}, i), do: {:tidal, wm, i, MapSet.put(empty, i)}
  defp do_put({:tidal, lwm, hwm, ids}, i) when i == lwm + 1, do: contig({:tidal, i, hwm, ids})
  defp do_put({:tidal, lwm, hwm, ids}, i), do: {:tidal, lwm, max(i, hwm), MapSet.put(ids, i)}

  # raise the lwm, consuming members of the ids set
  # until a new gap is found, 
  # or lwm == hwm and the set is empty
  @spec contig(tidal()) :: tidal()

  defp contig({:tidal, wm, wm, _empty} = seq), do: seq

  defp contig({:tidal, lwm, hwm, ids}) when hwm > lwm do
    next = lwm + 1

    if not MapSet.member?(ids, next) do
      {:tidal, lwm, hwm, ids}
    else
      contig({:tidal, next, hwm, MapSet.delete(ids, next)})
    end
  end
end
