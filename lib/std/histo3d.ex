defmodule Exa.Std.Histo3D do
  @moduledoc """
  3D Histogram.

  A count of occurrences of triples of 
  0-based positive integers (data, index or color values).

  The dimensions of the histogram are variable.
  The extent increased to accommodate new large values.

  The dimensions of the histogram are labelled 'I,J,K'.
  It is imagined that 'I' is the horizontal x-axis,
  'J' is the vertical y-axis,
  and 'K' is the vertical y-axis.

  In principle, the minimum count should be 0,
  but in practice, there may be reasons 
  why changes come in out-of-order.
  So counts may be temporarily below 0, 
  but will be eventually consistent with 0.

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

  alias Exa.Space.BBox3i

  # -----------------
  # public functions
  # -----------------

  @doc "Create new empty 3D histogram."
  @spec new() :: H.histo3d()
  def new(), do: Map.new()

  @doc """
  Create new 3D histogram from a list of increments.
  Each increment adds one count to the histogram bin.
  """
  @spec new([H.bin3d()]) :: H.histo3d()
  def new(bins) when is_list(bins), do: Enum.reduce(bins, new(), &inc(&2, &1))

  @doc "Get the count for a bin."
  @spec get(H.histo3d(), H.bin3d()) :: E.count()
  def get(h, b) when is_histo3d(h) and is_bin3d(b), do: Map.get(h, b, 0)

  @doc "Add one count to a bin of the histogram."
  @spec inc(H.histo3d(), H.bin3d()) :: H.histo3d()
  def inc(histo, bin) when is_histo3d(histo) and is_bin3d(bin) do
    # allow negative values for non-determinism
    # delete final 0 counts to keep the map sparse
    case Map.get(histo, bin, 0) do
      -1 -> Map.delete(histo, bin)
      n -> Map.put(histo, bin, n + 1)
    end
  end

  @doc "Subtract one count from a bin of the histogram."
  @spec dec(H.histo3d(), H.bin3d()) :: H.histo3d()
  def dec(histo, bin) when is_histo3d(histo) and is_bin3d(bin) do
    # allow negative values for non-determinism
    # delete final 0 counts to keep the map sparse
    case Map.get(histo, bin, 0) do
      1 -> Map.delete(histo, bin)
      n -> Map.put(histo, bin, n - 1)
    end
  end

  @doc """
  Extent of the histogram in each dimension.
  Each dimension is bounded by 0,
  and the last bin with a non-zero count.

  The result is an `{idim,jdim}` pair,
  for the maximum i and j values,
  even if that maximal bin is not actually populated.
  """
  @spec size(H.histo3d()) :: H.bin3d()
  def size(histo) when is_histo3d(histo) do
    histo
    |> Map.keys()
    |> Enum.reduce({0, 0, 0}, fn {i, j, k}, {imax, jmax, kmax} ->
      {max(i, imax), max(j, jmax), max(k, kmax)}
    end)
  end

  @doc """
  The number of bins in the histogram with a non-zero count.

  The number of bins will be:
  - 0 _empty_ no values
  - 1 _homogeneous_ all values the same
  - n otherwise
  """
  @spec nbins(H.histo3d()) :: E.count()
  def nbins(histo) when is_histo3d(histo), do: map_size(histo)

  @doc """
  Test if the histogram has all values in one bin.
  If it does, return the data index of the bin that has +ve count.
  """
  @spec homogeneous(H.histo3d()) :: :empty | :not_homo | {:homo, H.bin3d()}
  def homogeneous(histo) do
    case map_size(histo) do
      0 -> :empty
      1 -> {:homo, histo |> Enum.take(1) |> hd() |> elem(0)}
      _ -> :not_homo
    end
  end

  @doc """
  The total number of data values in the histogram.
  The sum of all the counts.
  """
  @spec total_count(H.histo3d()) :: E.count()
  def total_count(histo) when is_histo3d(histo), do: histo |> Map.values() |> Enum.sum()

  @doc """
  Convert to a sorted list of counts for each 3D bin.
  """
  @spec to_list(H.histo3d()) :: [{H.bin3d(), E.count()}]
  def to_list(histo) when is_histo3d(histo), do: histo |> Map.to_list() |> Enum.sort()

  # TODO - need extents (min,max) here, 
  #        then crop result is in context
  #        now we have problem - rebase to 0-based, or keep imin-imax indices?

  @doc "Crop (clip) a histogram to a bounding box in the bin labels."
  @spec crop(H.histo3d(), S.bbox3i()) :: H.histo3d()
  def crop(h, bbox) when is_histo3d(h) and is_bbox3i(bbox) do
    Map.filter(h, fn {bin, _} -> BBox3i.classify(bbox, bin) != :outside end)
  end
end
