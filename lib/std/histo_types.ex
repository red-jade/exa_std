defmodule Exa.Std.HistoTypes do
  @moduledoc """
  Types for 1D, 2D, 3D histograms in the Exa standard library.

  The data values for the histograms are non-negative integers.
  """

  alias Exa.Types, as: E

  @typedoc "A non-negative integer data value."
  @type hvalue() :: non_neg_integer()
  defguard is_hval(i) when is_integer(i) and i >= 0

  @typedoc "A bin in a 2d histogram."
  @type bin2d() :: {hvalue(), hvalue()}
  defguard is_bin2d(b)
           when is_tuple(b) and tuple_size(b) == 2 and
                  is_hval(elem(b, 0)) and is_hval(elem(b, 1))

  @typedoc "A bin in a 3d histogram."
  @type bin3d() :: {hvalue(), hvalue(), hvalue()}
  defguard is_bin3d(b)
           when is_tuple(b) and tuple_size(b) == 3 and
                  is_hval(elem(b, 0)) and is_hval(elem(b, 1)) and is_hval(elem(b, 2))

  @typedoc """
  A change in a 2d value pair, expressed as a delta vector.

  The value changes (moves) by the vector,
  so the original bin is decermented
  and the final bin is incremented.

  A zero delta of {0,0} is not allowed (no change).
  """
  @type delta2d() :: {integer(), integer()}
  defguard is_delta2d(d)
           when is_tuple(d) and tuple_size(d) == 2 and is_integer(elem(d, 0)) and
                  is_integer(elem(d, 1))

  @typedoc """
  A change in a 3d value triple, expressed as a delta vector.

  The value changes (moves) by the vector,
  so the original bin is decermented
  and the final bin is incremented.

  A zero delta of {0,0,0} is not allowed (no change).
  """
  @type delta3d() :: {integer(), integer(), integer()}
  defguard is_delta3d(d)
           when is_tuple(d) and tuple_size(d) == 3 and
                  is_integer(elem(d, 0)) and is_integer(elem(d, 1)) and is_integer(elem(d, 2))

  @typedoc "A 1D histogram with a count for an index bin value."
  @type histo1d() :: :array.array(E.count())

  @typedoc """
  A 2D histogram with a count for a 2D bin value.
  """
  @type histo2d() :: %{{hvalue(), hvalue()} => E.count()}
  defguard is_histo2d(h) when is_map(h)

  @typedoc """
  A 3D histogram with a count for a 3D bin value.
  """
  @type histo3d() :: %{{hvalue(), hvalue(), hvalue()} => E.count()}
  defguard is_histo3d(h) when is_map(h)
end
