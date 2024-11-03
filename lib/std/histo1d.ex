defmodule Exa.Std.Histo1D do
  @moduledoc """
  1D Histogram.

  A table of counts of occurrences of 0-based 
  positive integers (data index values).

  The bins in the histogram are labelled with 0-based
  positive integers. 

  The effective size is 0 up to the highest bin 
  with a non-zero count.
  If that bin has label `bmax`, the size is `bmax + 1`.
  Histogram bins are labelled in the range `0..(size - 1)`.

  The size of the histogram is variable.
  The extent is increased to accommodate new large values.

  In principle, the minimum count should be 0,
  but in practice, there may be reasons 
  why changes come in out-of-order.
  So counts are allowed to be below 0 temporarily, 
  but should be eventually consistent with 0.

  This implementation uses `:erlang.array`.
  """
  require Logger

  import Exa.Types
  alias Exa.Types, as: E

  alias Exa.Space.Types, as: S

  import Exa.Std.HistoTypes
  alias Exa.Std.HistoTypes, as: H

  # -----------------
  # public functions
  # -----------------

  @doc "Create new histogram with default size."
  @spec new() :: H.histo1d()
  def new() do
    :array.new([{:fixed, false}, {:default, 0}])
  end

  @doc """
  Create new histogram.

  Passing a single integer sets the initial size.

  Passing a list of integers sets them as the counts,
  starting at index 0. Counts must be non-negative.
  Raises error if any counts are negative.
  """
  @spec new(pos_integer() | [E.count(), ...]) :: H.histo1d()

  def new(n) when is_integer(n) and n > 1 do
    :array.new(n, [{:fixed, false}, {:default, 0}])
  end

  def new(counts) when is_list(counts) do
    if Enum.any?(counts, fn x -> not is_int_nonneg(x) end) do
      msg = "Negative count: #{inspect(counts)}"
      Logger.error(msg)
      raise ArgumentError, message: msg
    end

    :array.from_list(counts, 0)
  end

  @doc "Set the count at an index."
  @spec get(H.histo1d(), H.hvalue()) :: E.count()
  def get(h, i) when is_hval(i), do: :array.get(i, h)

  @doc "Set the count at an index."
  @spec set(H.histo1d(), H.hvalue(), E.count()) :: H.histo1d()
  def set(h, i, n) when is_hval(i), do: :array.set(i, n, h)

  @doc "Add one count to a bin of the histogram."
  @spec inc(H.histo1d(), H.hvalue()) :: H.histo1d()
  def inc(histo, i) when is_hval(i), do: set(histo, i, get(histo, i) + 1)

  @doc """
  Subtract one count from a bin of the histogram.

  Allow decrement of zero count, 
  and tolerate transient negative values,
  for race conditions in asynchronus systems. 
  """
  @spec dec(H.histo1d(), H.hvalue()) :: H.histo1d()
  def dec(histo, i) when is_hval(i) do
    count = get(histo, i)

    if count <= 0, do: Logger.info("Negative count for value #{i}")

    set(histo, i, count - 1)
  end

  @doc """
  Increase a value by 1. This is a value not a count.
  It is a change in a value already assigned in the histogram.
  The total count remains the same.

  Decrement the count for the current value.

  Increment the count for the new higher value.
  """
  @spec add(H.histo1d(), H.hvalue()) :: H.histo1d()
  def add(histo, i) when is_hval(i), do: histo |> dec(i) |> inc(i + 1)

  @doc """
  Decrease a value by 1. This is a value not a count.
  It is a change in a value already assigned in the histogram.
  The total count remains the same.

  Decrement the count for the current value.

  Increment the count for the new lower value.
  """
  @spec sub(H.histo1d(), H.hvalue()) :: H.histo1d()
  def sub(histo, i) when is_hval(i) and i > 0, do: histo |> dec(i) |> inc(i - 1)

  @doc """
  Size of the histogram from 0 up to the 
  last index value with a non-zero count.
  """
  @spec size(H.histo1d()) :: E.count()
  def size(histo), do: :array.sparse_size(histo)

  @doc """
  The number of bins in the histogram with a non-zero count.

  The number of bins will be:
  - 0 _empty_ no values
  - 1 _homogeneous_ all the same value
  - n otherwise, with different values
  """
  @spec nbins(H.histo1d()) :: E.count()
  def nbins(histo) do
    # should not get called with n > 0 in sparse_foldl, but handle anyway
    # allow -ve values, so don't guard for n > 0
    :array.sparse_foldl(
      fn
        _i, 0, nbin -> nbin
        _i, _n, nbin -> nbin + 1
      end,
      0,
      histo
    )
  end

  @doc """
  Test if the histogram has all values in one bin.
  If it does, return the index of the bin that has +ve count.
  """
  @spec homogeneous(H.histo1d()) :: :empty | :not_homo | {:homo, H.hvalue()}
  def homogeneous(histo) do
    # should not get called with n > 0 in sparse_foldl, but guard anyway
    # allow -ve value, so don't guard with n > 0, use n != 0
    :array.sparse_foldl(
      fn
        i, n, :empty when n != 0 -> {:homo, i}
        _i, _n, :not_homo -> :not_homo
        _i, n, {:homo, _j} when n != 0 -> :not_homo
      end,
      :empty,
      histo
    )
  end

  @doc """
  The total number of data values in the histogram.
  The sum of all the counts.
  """
  @spec total_count(H.histo1d()) :: E.count()
  def total_count(histo), do: :array.sparse_foldl(fn _i, n, sum -> sum + n end, 0, histo)

  @doc """
  The total value of all the data represented in the histogram.
  Sum the product of array index value and count.
  """
  @spec total_value(H.histo1d()) :: E.count()
  def total_value(histo), do: :array.sparse_foldl(fn i, n, sum -> sum + i * n end, 0, histo)

  @doc """
  Mean of the values.
  The total value divided by the total count.
  """
  @spec mean(H.histo1d()) :: float()
  def mean(histo), do: total_value(histo) / total_count(histo)

  @doc """
  Median of the values.

  The value depends on the total count:
  - odd: return the index of the bin containing the central value
  - even: average the two bins containing the two central values
    (which could be the same bin)

  Returns error if the histogram is empty, or has negative total count.
  """
  @spec median(H.histo1d()) :: number() | {:error, any()}
  def median(histo) do
    case {size(histo), total_count(histo)} do
      {0, 0} -> {:error, "Empty histogram"}
      {_, n} when n < 0 -> {:error, "Negative total count"}
      {_, n} when is_int_even(n) -> meven(histo, 0, div(n, 2), 0)
      {_, n} when is_int_odd(n) -> modd(histo, 0, div(n, 2) + 1, 0)
    end
  end

  defp meven(h, i, m, s) when s < m, do: meven(h, i + 1, m, s + get(h, i))
  defp meven(h, i, m, s) when s == m, do: (i - 1 + mnext(h, i)) / 2
  defp meven(_h, i, m, s) when s > m, do: i - 1

  defp mnext(h, i), do: if(get(h, i) > 0, do: i, else: mnext(h, i + 1))

  defp modd(h, i, m, s) when s < m, do: modd(h, i + 1, m, s + get(h, i))
  defp modd(_h, i, _m, _s), do: i - 1

  @doc """
  Convert to a Probability Density Function (PDF).

  Normalize the probabilities 
  by dividing the individual counts by the total count.

  The result is a dense (complete) list of probability values,
  with elements for all bins from 0 to the maximum non-zero count.

  The probabilities are typically in the range 0.0-1.0, 
  but may contain negative values if there have been out-of-order updates.

  Returns the empty list if the size is 0.

  Returns error if the total count is zero for a non-empty histogram
  (i.e. contains negative counts that balance positive counts).
  """
  @spec pdf(H.histo1d()) :: [float()] | {:error, any()}
  def pdf(histo) do
    case {size(histo), total_count(histo)} do
      {0, 0} -> []
      {_, 0} -> {:error, "Zero total count for non-empty histogram"}
      {_, n} -> histo |> to_list() |> Enum.map(fn i -> i / n end)
    end
  end

  @doc """
  Convert to a Cumulative Density Function (CDF).

  Calculate a running total of counts and 
  normalize to probabilities by dividing by the total count.

  The result is a dense (complete) list of probability values,
  with elements for all bins from 0 to the maximum non-zero count.

  The probability values are monotonically flat or increasing.
  The final value should be 1.0.

  The probabilities are typically in the range 0.0-1.0, 
  but may contain negative values if there have been out-of-order updates.

  Returns the empty list if the size is 0.

  Returns error if the total count is zero for a non-empty histogram
  (i.e. contains negative counts that balance positive counts).
  """
  @spec cdf(H.histo1d()) :: [float()] | {:error, any()}
  def cdf(histo) do
    case {size(histo), total_count(histo)} do
      {0, 0} ->
        []

      {_, 0} ->
        {:error, "Zero total count for non-empty histogram"}

      {_, n} ->
        {^n, cdf} =
          histo
          |> to_list()
          |> Enum.reduce({0, []}, fn i, {s, cdf} ->
            s = s + i
            {s, [s / n | cdf]}
          end)

        Enum.reverse(cdf)
    end
  end

  @doc """
  Convert to a list.

  The list is the 0-based sequence of all counts.
  The last entry is the last non-zero count value.
  """
  @spec to_list(H.histo1d()) :: [E.count()]
  def to_list(histo), do: histo |> :array.resize() |> :array.to_list()

  @doc """
  Convert to a sparse list of pairs of non-zero counts.
  """
  @spec to_sparse_list(H.histo1d()) :: [{H.hvalue(), E.count()}]
  def to_sparse_list(histo), do: spar(histo, size(histo), [])

  defp spar(_histo, -1, pairs), do: pairs

  defp spar(histo, i, pairs) do
    case get(histo, i) do
      0 -> spar(histo, i - 1, pairs)
      n -> spar(histo, i - 1, [{i, n} | pairs])
    end
  end

  # TODO - need extents (min,max) here, 
  #        then crop result is in context
  #        now we have problem - rebase to 0-based, or keep imin-imax indices?

  @doc "Crop (clip) a histogram to a bounding box in the bin labels."
  @spec crop(H.histo1d(), S.bbox1i()) :: H.histo1d()
  def crop(h, {imin, imax}) when is_range(imin, imax) do
    Enum.reduce(imin..imax, new(), fn i, hnew ->
      case get(h, i) do
        # n > 0 -> set(hnew, i - imin, n)
        n when n > 0 -> set(hnew, i, n)
        _ -> hnew
      end
    end)
  end
end
