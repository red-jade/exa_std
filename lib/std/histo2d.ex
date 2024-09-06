defmodule Exa.Std.Histo2D do
  @moduledoc """
  2D Histogram.

  A table of counts of occurrences of pairs of 
  0-based non-negative integers (data index values).

  The bins in the histogram are labelled with 
  pairs of 0-based non-negative integers. 

  The effective size in each direction
  is from 0 up to the highest bin with a non-zero count.
  The total extent is the combination of these two sizes,
  even if the actual maximal bin has a zero count.

  The dimensions of the histogram are variable.
  The extent increased to accommodate new large values.

  The dimensions of the histogram are labelled 'I' and 'J'.
  It is imagined that 'I' is the horizontal x-axis,
  and 'J' is the vertical y-axis.

  In principle, the minimum count should be 0,
  but in practice, there may be reasons 
  why changes come in out-of-order.
  So counts may be temporarily below 0, 
  but should be eventually consistent with 0.

  The implementation uses a sparse map.
  Entries only exist for non-zero count.
  Every other count is assumed to be zero.
  It will be large and inefficient for dense data.
  """

  alias Exa.Types, as: E

  import Exa.Space.Types
  alias Exa.Space.Types, as: S

  import Exa.Std.HistoTypes
  alias Exa.Std.HistoTypes, as: H

  alias Exa.Space.BBox2i

  # -----------------
  # public functions
  # -----------------

  @doc "Create new empty 2D histogram."
  @spec new() :: H.histo2d()
  def new(), do: Map.new()

  @doc """
  Create new 2D histogram from a list of increments.
  Each increment adds one count to the histogram bin.
  """
  @spec new([H.bin2d()]) :: H.histo2d()
  def new(bins) when is_list(bins), do: Enum.reduce(bins, new(), &inc(&2, &1))

  @doc "Get the count for a bin."
  @spec get(H.histo2d(), H.bin2d()) :: E.count()
  def get(h, b) when is_histo2d(h) and is_bin2d(b), do: Map.get(h, b, 0)

  @doc "Get the maximum count."
  @spec max_count(H.histo2d()) :: E.count()
  def max_count(h), do: h |> Map.values() |> Enum.max(fn -> 0 end) |> max(0)

  @doc "Add one count to a bin of the histogram."
  @spec inc(H.histo2d(), H.bin2d()) :: H.histo2d()
  def inc(histo, bin) when is_histo2d(histo) and is_bin2d(bin) do
    # allow negative values for non-determinism
    # delete final 0 counts to keep the map sparse
    case Map.get(histo, bin, 0) do
      -1 -> Map.delete(histo, bin)
      n -> Map.put(histo, bin, n + 1)
    end
  end

  @doc "Subtract one count from a bin of the histogram."
  @spec dec(H.histo2d(), H.bin2d()) :: H.histo2d()
  def dec(histo, bin) when is_histo2d(histo) and is_bin2d(bin) do
    # allow negative values for non-determinism
    # delete final 0 counts to keep the map sparse
    case Map.get(histo, bin, 0) do
      1 -> Map.delete(histo, bin)
      n -> Map.put(histo, bin, n - 1)
    end
  end

  @doc """
  Increase an existing I-value by 1. 

  Make a change with a delta move of `{1,0}`.
  The total count stays the same.

  Decrement the count for the current bin.
  Increment the count for the new higher bin.
  """
  @spec add_i(H.histo2d(), H.bin2d()) :: H.histo2d()
  def add_i(histo, bin), do: delta(histo, bin, {1, 0})

  @doc """
  Increase an existing J-value by 1. 

  Make a change with a delta move of `{0,1}`.
  The total count stays the same.

  Decrement the count for the current bin.
  Increment the count for the new higher bin.
  """
  @spec add_j(H.histo2d(), H.bin2d()) :: H.histo2d()
  def add_j(histo, bin), do: delta(histo, bin, {0, 1})

  @doc """
  Decrease an I-value by 1. 

  Make a change with a delta move of `{-1,0}`.
  The total count stays the same.

  Decrement the count for the current bin.
  Increment the count for the new lower bin.
  """
  @spec sub_i(H.histo2d(), H.bin2d()) :: H.histo2d()
  def sub_i(histo, bin), do: delta(histo, bin, {-1, 0})

  @doc """
  Decrease an existsing J-value by 1. 

  Make a change with a delta move of `{0,-1}`.
  The total count stays the same.

  Decrement the count for the current bin.
  Increment the count for the new lower bin.
  """
  @spec sub_j(H.histo2d(), H.bin2d()) :: H.histo2d()
  def sub_j(histo, bin), do: delta(histo, bin, {0, -1})

  @doc """
  Change an existing value by a delta vector. 

  The total count stays the same.

  Decrement the count for the current bin.
  Increment the count for the new bin at the end of the vector.
  """
  @spec delta(H.histo2d(), H.bin2d(), H.delta2d()) :: H.histo2d()
  def delta(histo, {i, j} = bin, {di, dj} = del)
      when is_histo2d(histo) and is_bin2d(bin) and is_delta2d(del) do
    histo |> dec(bin) |> inc({i + di, j + dj})
  end

  @doc """
  Extent of the histogram in each dimension.
  Each dimension is bounded by 0,
  and the last bin with a non-zero count.

  The result is an `{idim,jdim}` pair,
  for the maximum i and j values,
  even if that maximal bin is not actually populated.
  """
  @spec size(H.histo2d()) :: H.bin2d()
  def size(histo) when is_histo2d(histo) do
    histo
    |> Map.keys()
    |> Enum.reduce({0, 0}, fn {i, j}, {imax, jmax} ->
      {max(i, imax), max(j, jmax)}
    end)
  end

  @doc """
  The number of bins in the histogram with a non-zero count.

  The number of bins will be:
  - 0 _empty_ no values
  - 1 _homogeneous_ all values the same
  - n otherwise
  """
  @spec nbins(H.histo2d()) :: E.count()
  def nbins(histo) when is_histo2d(histo), do: map_size(histo)

  @doc """
  Test if the histogram has all values in one bin.
  If it does, return the data index of the bin that has +ve count.
  """
  @spec homogeneous(H.histo2d()) :: :empty | :not_homo | {:homo, H.bin2d()}
  def homogeneous(histo) do
    case map_size(histo) do
      0 -> :empty
      1 -> {:homo, histo |> Map.to_list() |> hd() |> elem(0)}
      _ -> :not_homo
    end
  end

  @doc """
  The total number of data values in the histogram.
  The sum of all the counts.
  """
  @spec total_count(H.histo2d()) :: E.count()
  def total_count(histo) when is_histo2d(histo), do: histo |> Map.values() |> Enum.sum()

  @doc """
  Convert to a sorted list of counts for each 2D bin.
  """
  @spec to_list(H.histo2d()) :: [{H.bin2d(), E.count()}]
  def to_list(histo) when is_histo2d(histo), do: histo |> Map.to_list() |> Enum.sort()

  # TODO - need extents (min,max) here, 
  #        then crop result is in context
  #        now we have problem - rebase to 0-based, or keep imin-imax indices?

  @doc "Crop (clip) a histogram to a bounding box in the bin labels."
  @spec crop(H.histo2d(), S.bbox2i()) :: H.histo3d()
  def crop(h, bbox) when is_histo2d(h) and is_bbox2i(bbox) do
    Map.filter(h, fn {bin, _} -> BBox2i.classify(bbox, bin) != :outside end)
  end
end
