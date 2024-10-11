defmodule Exa.Std.Histo do
  @moduledoc """
  Generalized histogram.

  A map of counts of occurrences of arbitrary data values.

  In principle, the minimum count should be 0,
  but in practice, there may be reasons 
  why changes come in out-of-order.
  So counts may be temporarily below 0, 
  but should be eventually consistent with 0.
  """

  alias Exa.Types, as: E

  import Exa.Std.HistoTypes
  alias Exa.Std.HistoTypes, as: H

  # -----------------
  # public functions
  # -----------------

  @doc "Create new empty histogram."
  @spec new() :: H.histo()
  def new(), do: Map.new()

  @doc """
  Create new 2D histogram from a list of data values.
  Each value adds one count to the histogram bin.
  """
  @spec new([any()]) :: H.histo()
  def new(data) when is_list(data), do: Enum.reduce(data, new(), &inc(&2, &1))

  @doc "Get the count for a bin."
  @spec get(H.histo(), any()) :: E.count()
  def get(h, d) when is_histo(h), do: Map.get(h, d, 0)

  @doc "Add one count to a bin of the histogram."
  @spec inc(H.histo(), any()) :: H.histo()
  def inc(histo, d) when is_histo(histo) do
    # allow negative values for non-determinism
    # delete final 0 counts to keep the map sparse
    case Map.get(histo, d, 0) do
      -1 -> Map.delete(histo, d)
      n -> Map.put(histo, d, n + 1)
    end
  end

  @doc "Subtract one count from a bin of the histogram."
  @spec dec(H.histo(), any()) :: H.histo()
  def dec(histo, d) when is_histo(histo) do
    # allow negative values for non-determinism
    # delete final 0 counts to keep the map sparse
    case Map.get(histo, d, 0) do
      1 -> Map.delete(histo, d)
      n -> Map.put(histo, d, n - 1)
    end
  end

  @doc """
  The number of bins in the histogram with a non-zero count.

  The number of bins will be:
  - 0 _empty_ no values
  - 1 _homogeneous_ all values the same
  - n otherwise
  """
  @spec nbins(H.histo()) :: E.count()
  def nbins(histo) when is_histo(histo), do: map_size(histo)

  @doc """
  Test if the histogram has all values in one bin.
  If it does, return the data index of the data value that has +ve count.
  """
  @spec homogeneous(H.histo()) :: :empty | :not_homo | {:homo, any()}
  def homogeneous(histo) do
    case map_size(histo) do
      0 -> :empty
      1 -> {:homo, histo |> Enum.take(1) |> hd() |> elem(0)}
      _ -> :not_homo
    end
  end

  @doc """
  Get the maximum count, 
  together with a list of values that have that count.

  If the histogram is empty, or contains only negative counts,
  return `{0, []}`.
  """
  @spec max_count(H.histo()) :: {E.count(), [any()]}
  def max_count(histo) when is_histo(histo) do
    Enum.reduce(histo, {0, []}, fn
      {d, n}, {nmax, _ds} when n > nmax -> {n, [d]}
      {d, nmax}, {nmax, ds} -> {nmax, [d | ds]}
      _, acc -> acc
    end)
  end

  @doc """
  Get the minimum positive count, 
  together with a list of values that have that count.

  If the histogram is empty, or contains only negative counts,
  return `{0, []}`.
  """
  @spec min_count(H.histo()) :: {E.count(), [any()]}
  def min_count(histo) when is_histo(histo) do
    case Enum.find(histo, fn {_, n} -> n > 0 end) do
      nil ->
        {0, []}

      {_, n0} ->
        Enum.reduce(histo, {n0, []}, fn
          {d, n}, {nmin, _ds} when n > 0 and n < nmin -> {n, [d]}
          {d, nmin}, {nmin, ds} -> {nmin, [d | ds]}
          _, acc -> acc
        end)
    end
  end

  @doc """
  The total number of data values in the histogram.
  The sum of all the counts.
  """
  @spec total_count(H.histo()) :: E.count()
  def total_count(histo) when is_histo(histo), do: histo |> Map.values() |> Enum.sum()
end
