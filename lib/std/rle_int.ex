defmodule Exa.Std.RleInt do
  @moduledoc """
  Run Length Encoded (RLE) list of integers,
  with lossless compression of the tail 
  using binary delta values.

  The integer RLE has a fixed number of bits
  to express delta values. 
  The delta size can be 4-19 bits.

  The head of the RLE is always kept  
  as a single value for pattern matching.

  An integer RLE is a list containing a sequence of either:
  - raw integer value 
    (the head is always a raw integer)
  - rle tuple, containing:
    - base minimum integer value
    - bitstring containing encoded deltas above the base value
      
  The first 4 bits of the bitstring contain the size of each delta.
  The bias on the size is +4. So with 4 bits, the value can be 0-15
  and the actual biased sizes for the delta are 4-19 bits.
  [In principle, different runs could have a different delta size,
  but in the current implementation, they are all the same.]

  There is no count of elements in the rle tuple.
  The number is calculated O(1) from the size of the bitstring.

  The delta bit size can be calculated automatically
  using the data range: pass `:auto` to the constructor (default).

  If the range of all values fits inside the delta range,
  then the whole tail can be captured in one RLE element,
  with a single binary for all values (highest compression).

  Note that imposing a minimum delta size 
  prevents efficient compression for:
  - constant-valued runs: consider using `Exa.Std.Rle`.
  - single-bit boolean lists: consider raw bitstring 
    with `Exa.Binary` utils, or perhaps `Exa.Image.Bitmap`.
  """
  import Bitwise

  import Exa.Types
  alias Exa.Types, as: E

  require Exa.Binary
  alias Exa.Binary

  # ---------
  # constants
  # ---------

  # the number of bits used to contain the bit size of delta values
  # the actual size value is adjusted by the minimum size
  # for example, if hdr_sz is 4, the stored value is 0-15,
  # if the minimum size is 4, then the adjusted size is 4-19

  @hdr_sz 4

  @min_dbit 4

  @max_dbit @min_dbit + (1 <<< @hdr_sz) - 1

  # the default minimum length for building an RLE

  @def_min_len 64

  # -----
  # types
  # -----

  # module attributes cannot be used in type declarations
  # @min_dbit..@max_dbit

  @typedoc "The bit size of each delta value."
  @type delta_bits() :: 4..19

  @typedoc """
  The bit size of each delta value, 
  or `:auto` flag for automatic delta calculation.
  """
  @type delta_size() :: :auto | delta_bits()

  @typedoc "A run length element."
  @type drun() :: {imin :: integer(), deltas :: E.bits()}

  @typedoc "An integer or a delta run."
  @type irun() :: integer() | drun()

  @typedoc "A run length encoded integer list."
  @type irle() :: [irun()]
  defguard is_irle(irle) when is_list(irle)

  # -----------
  # constructor
  # -----------

  @doc """
  Create new RLE from an existing list.

  The `delta_size` argument can be:
  - fixed number of bits
  - a `{min,max}` range of input
    used to calculate the number of bits
  - `:auto` flag to calculate the number of bits 
    from the range in the actual data O(n).

  The final `delta_bit` integer value is clamped to the range 4-19.

  If the input list is not more than `min_length` (default 64),
  it will be returned as-is, without any encoded runs.
  """
  @spec new([integer()], :auto | E.count() | {integer(), integer()}, E.count2()) :: irle()
  def new(is \\ [], delta_size \\ :auto, min_length \\ @def_min_len)

  def new(is, _, min_length) when length(is) <= min_length, do: is

  def new(is, :auto, min_len), do: new(is, minmax(is), min_len)

  def new(is, {imin, imax}, min_len) when is_range(imin, imax) do
    new(is, Binary.nbits(imax - imin), min_len)
  end

  def new([i | tail], nbit, _) when is_integer(i) and is_count1(nbit) do
    dbit = Exa.Math.clamp(@min_dbit, nbit, @max_dbit)
    if dbit != nbit, do: IO.puts("Warning [IntRle]: clamping delta bit size to #{dbit}")
    [i | encode(tail, dbit, 1 <<< dbit, [])]
  end

  # encode the tail of the list into sequence of raw integers and delta runs
  @spec encode([integer()], delta_bits(), pos_integer(), irle()) :: irle()

  defp encode([i | [j | _]] = is, dbit, dmax, irle) when abs(j - i) < dmax do
    {imin, n} = calc(tl(is), i, i, dmax, 1)
    {deltas, irest} = wdeltas(is, n, imin, dbit)
    encode(irest, dbit, dmax, [{imin, deltas} | irle])
  end

  defp encode([i | is], dbit, dmax, irle), do: encode(is, dbit, dmax, [i | irle])

  defp encode([], _dbit, _dmax, irle), do: Enum.reverse(irle)

  # calculate the min value and length of a delta run
  @spec calc([integer(), ...], integer(), integer(), pos_integer(), E.count1()) ::
          {integer(), E.count1()}

  defp calc([i | is], imin, imax, dmax, n) when is_in_range(imin, i, imax) do
    # continue run with existing imin and imax
    calc(is, imin, imax, dmax, n + 1)
  end

  defp calc([i | is], imin, imax, dmax, n) when i < imin and imax - i < dmax do
    # change imin and continue run
    calc(is, i, imax, dmax, n + 1)
  end

  defp calc([i | is], imin, imax, dmax, n) when i > imax and i - imin < dmax do
    # change imax and continue run
    calc(is, imin, i, dmax, n + 1)
  end

  defp calc(_, imin, _imax, _dmax, n) do
    # end of run, either delta is too big, or end of input list
    {imin, n}
  end

  # ------
  # output
  # ------

  @doc "Convert an integer RLE to a list."
  @spec to_list(irle()) :: [integer()]
  def to_list([] = xs), do: xs
  def to_list([_] = xs), do: xs
  def to_list([_, j] = xs) when is_integer(j), do: xs

  def to_list(irle) when is_irle(irle) do
    irle
    |> Enum.reduce([], fn
      {imin, deltas}, out ->
        {dval, deltas} = Binary.uint(deltas, @hdr_sz)
        rdeltas(deltas, imin, dval + @min_dbit, out)

      i, out when is_integer(i) ->
        [i | out]
    end)
    |> Enum.reverse()
  end

  # ---------
  # accessors
  # ---------

  @doc "Get the total length of the RLE."
  @spec size(irle()) :: E.count()
  def size(irle) when is_irle(irle) do
    Enum.reduce(irle, 0, fn
      {_, deltas}, n -> n + (deltas |> dsize() |> elem(0))
      i, n when is_integer(i) -> n + 1
    end)
  end

  @doc """
  Get the integer value at 0-based position.

  Fails if the requested index exceeds the size of the RLE. 
  """
  @spec at(irle(), E.index0()) :: integer()
  def at([i | _], 0) when is_integer(i), do: i
  def at([i | irle], n) when is_integer(i) and is_index0(n), do: at(irle, n - 1)

  def at([{imin, deltas} | irle], n) when is_index0(n) do
    {ndel, dbit, dels} = dsize(deltas)

    cond do
      n < ndel -> imin + rdel(dels, dbit, n)
      true -> at(irle, n - ndel)
    end
  end

  def at([], _), do: raise(ArgumentError, message: "Index out of range")

  @doc """
  Get the compression of the RLE in memory,
  as a percentage reduction compared to the original list.

  A negative compression means an expansion in memory.
  An expansion is very likely for short lists,
  or those with a `delta_bit` set too low compared with 
  the actual dynamic range of the data 
  (many short encoded delta runs).

  Calls `to_list` so O(n).
  """
  @spec compression(irle()) :: integer()
  def compression(irle) when is_irle(irle) do
    rawsize = :erts_debug.size(to_list(irle))
    rlesize = :erts_debug.size(irle)
    round(100.0 * (1.0 - rlesize / rawsize))
  end

  # ------
  # update
  # ------

  @doc """
  Get the tail of the RLE. 
  Advance the RLE ignoring the head element.
  Fails for an empty RLE.
  """
  @spec next(irle()) :: irle()
  def next([_]), do: []
  def next([_ | [j | _] = irle]) when is_integer(j), do: irle

  def next([_, {imin, deltas} | irle]) do
    {ndel, dbit, dels} = dsize(deltas)
    {d0, dels} = Binary.uint(dels, dbit)

    case ndel do
      2 ->
        {d1, <<>>} = Binary.uint(dels, dbit)
        [imin + d0, imin + d1 | irle]

      _ ->
        <<hdr::size(@hdr_sz), _::bits>> = deltas
        deltas = <<hdr::size(@hdr_sz), dels::bits>>
        [imin + d0, {imin, deltas} | irle]
    end
  end

  @doc """
  Take a plain list from the head of the RLE 
  and return the tail continuation as an RLE.

  If the requested prefix is longer than the RLE input,
  the whole list is returned with an empty RLE.
  """
  @spec take(irle(), E.count1()) :: {[integer()], irle()}
  def take(irle, n \\ 1) when is_irle(irle) and is_count1(n), do: do_take(irle, n, [])

  defp do_take(irle, 0, head), do: {Enum.reverse(head), irle}
  defp do_take([], _, head), do: {Enum.reverse(head), []}
  defp do_take([i | _] = irle, n, head), do: do_take(next(irle), n - 1, [i | head])

  # -------------------
  # map, zip and reduce
  # -------------------

  # NOTE sum/min/max are written efficiently without using next()

  @doc "Sum the Integer RLE."
  @spec sum(irle()) :: integer()
  def sum([i | irle]), do: do_sum(irle, i)

  @spec do_sum(irle(), integer()) :: integer()

  defp do_sum([{imin, deltas} | irle], sum) do
    {n, dbit, dels} = dsize(deltas)
    do_sum(irle, imin * n + sumdel(dels, dbit, sum))
  end

  defp do_sum([i | irle], sum) when is_integer(i), do: do_sum(irle, sum + i)

  defp do_sum([], sum), do: sum

  @spec sumdel(E.bits(), delta_bits(), integer()) :: integer()

  defp sumdel(<<>>, _, sum), do: sum

  defp sumdel(buf, dbit, sum) do
    {d, rest} = Binary.uint(buf, dbit)
    sumdel(rest, dbit, sum + d)
  end

  @doc "Maximum of the Integer RLE."
  @spec maximum(irle()) :: integer()
  def maximum([i | irle]), do: do_max(irle, i)

  @spec do_max(irle(), integer()) :: integer()

  defp do_max([{imin, deltas} | irle], max) do
    {_, dbit, dels} = dsize(deltas)
    do_max(irle, max(max, imin + maxdel(dels, dbit, 0)))
  end

  defp do_max([i | irle], max) when is_integer(i), do: do_max(irle, max(max, i))

  defp do_max([], max), do: max

  @spec maxdel(E.bits(), delta_bits(), integer()) :: integer()

  defp maxdel(<<>>, _, max), do: max

  defp maxdel(buf, dbit, max) do
    {d, rest} = Binary.uint(buf, dbit)
    maxdel(rest, dbit, max(max, d))
  end

  @doc "Minimum of the Integer RLE."
  @spec minimum(irle()) :: integer()
  def minimum([i | irle]), do: do_min(irle, i)

  @spec do_min(irle(), integer()) :: integer()
  defp do_min([{imin, _} | irle], min), do: do_min(irle, min(min, imin))
  defp do_min([i | irle], min) when is_integer(i), do: do_min(irle, min(min, i))
  defp do_min([], min), do: min

  # TODO - map can be rewritten more efficiently without using next()
  #        see the sum/min/max examples

  @doc """
  Map a function over an Integer RLE.

  Construct a new Integer RLE from the result, 
  using the delta size and min length arguments.

  If the input RLE is empty, then return the empty list.
  """
  @spec map(irle(), E.mapper(integer(), integer()), delta_size(), E.count2()) :: irle()
  def map(is, mapr, delta_size \\ :auto, min_length \\ @def_min_len)

  def map([], _, _, _), do: []

  def map([a | _] = ia, mapr, :auto, minl) do
    c = mapr.(a)
    {is, imin, imax} = do_map(next(ia), mapr, [c], c, c)
    new(is, {imin, imax}, minl)
  end

  def map([a | _] = ia, mapr, dbits, minl) do
    is = do_map(next(ia), mapr, [mapr.(a)])
    new(is, dbits, minl)
  end

  @spec do_map(irle(), E.mapper(integer(), integer()), [integer()]) :: [integer()]
  defp do_map([a | _] = ia, f, is), do: do_map(next(ia), f, [f.(a) | is])
  defp do_map([], _, is), do: Enum.reverse(is)

  # for auto RLE construction, calculate min/max in single pass
  @spec do_map(irle(), E.mapper(integer(), integer()), [integer()], integer(), integer()) ::
          {[integer()], integer(), integer()}

  defp do_map([a | _] = ia, f, is, imin, imax) do
    i = f.(a)
    do_map(next(ia), f, [i | is], min(i, imin), max(i, imax))
  end

  defp do_map(_, _, is, imin, imax), do: {Enum.reverse(is), imin, imax}

  @doc """
  Compute the dot product of two Integer RLE series.

  Halts and returns the result at the end of the shorter input.
  """
  @spec dot(irle(), irle()) :: integer()
  def dot(ia, ib), do: do_bired(ia, ib, 0, fn a, b, s -> s + a * b end)

  @doc """
  Zip two Integer RLEs together with a zip reducer function (bireducer).

  Halts and returns the result at the end of the shorter input.

  If either input RLE is empty, return the initial state unchanged.
  """
  @spec zip_reduce(irle(), irle(), integer(), E.bireducer(integer(), integer())) :: integer()
  def zip_reduce([], _, init, _), do: init
  def zip_reduce(_, [], init, _), do: init
  def zip_reduce(ia, ib, init, bired), do: do_bired(ia, ib, init, bired)

  @spec do_bired(irle(), irle(), integer(), E.bireducer(integer(), integer())) :: integer()
  defp do_bired([a | _] = ia, [b | _] = ib, s, f),
    do: do_bired(next(ia), next(ib), f.(a, b, s), f)

  defp do_bired(_, _, s, _), do: s

  @doc """
  Zip two Integer RLEs together with a zip combiner function (bimapper).

  Construct a new Integer RLE from the result, 
  using the delta size and min length arguments.

  Halts and returns the result at the end of the shorter input.

  If either input RLE is empty, then return the empty list.
  """
  @spec zip(irle(), irle(), E.bimapper(integer(), integer()), delta_size(), E.count2()) :: irle()
  def zip(ia, ib, bimap, delta_size \\ :auto, min_length \\ @def_min_len)

  def zip([], _, _, _, _), do: []
  def zip(_, [], _, _, _), do: []

  def zip([a | _] = ia, [b | _] = ib, bimap, :auto, minl) do
    i = bimap.(a, b)
    {is, imin, imax} = do_zip(next(ia), next(ib), bimap, [i], i, i)
    new(is, {imin, imax}, minl)
  end

  def zip(ia, ib, bimap, dbit, minl) do
    do_zip(ia, ib, bimap, []) |> new(dbit, minl)
  end

  @spec do_zip(irle(), irle(), E.bimapper(integer(), integer()), [integer()]) :: [integer()]
  defp do_zip([a | _] = ia, [b | _] = ib, f, is) do
    do_zip(next(ia), next(ib), f, [f.(a, b) | is])
  end

  defp do_zip(_, _, _, is), do: Enum.reverse(is)

  # for auto RLE construction, calculate min/max in same pass
  @spec do_zip(
          irle(),
          irle(),
          E.bimapper(integer(), integer()),
          [integer()],
          integer(),
          integer()
        ) ::
          {[integer()], integer(), integer()}

  defp do_zip([a | _] = ia, [b | _] = ib, f, is, imin, imax) do
    i = f.(a, b)
    do_zip(next(ia), next(ib), f, [i | is], min(i, imin), max(i, imax))
  end

  defp do_zip(_, _, _, is, imin, imax), do: {Enum.reverse(is), imin, imax}

  # -----------------
  # private functions
  # -----------------

  # read deltas from the buffer
  @spec rdeltas(E.bits(), integer(), delta_bits(), [integer(), ...]) :: [integer(), ...]

  defp rdeltas(<<>>, _imin, _, out), do: out

  defp rdeltas(buf, imin, dbit, out) do
    {d, rest} = Binary.uint(buf, dbit)
    rdeltas(rest, imin, dbit, [imin + d | out])
  end

  # write delta run from the first n values of the list
  @spec wdeltas([integer(), ...], E.count1(), integer(), delta_bits()) :: {E.bits(), [integer()]}
  defp wdeltas(is, n, imin, dbit) when length(is) >= n do
    hdr = Binary.append_uint(<<>>, dbit - @min_dbit, @hdr_sz)

    Enum.reduce(1..n, {hdr, is}, fn _, {deltas, [i | is]} ->
      {Binary.append_uint(deltas, i - imin, dbit), is}
    end)
  end

  # get the size of an individual delta run
  # together with the dbit size and remainder of the delta buffer
  @spec dsize(E.bits()) :: {E.count1(), delta_bits(), E.bits()}
  defp dsize(deltas) when is_bitstring(deltas) do
    {dval, dels} = Binary.uint(deltas, @hdr_sz)
    dbit = dval + @min_dbit
    {div(bit_size(dels), dbit), dbit, dels}
  end

  # get a delta value from 0-based position within the delta data buffer
  @spec rdel(E.bits(), delta_bits(), E.index0()) :: non_neg_integer()
  defp rdel(dels, dbit, n) when is_bitstring(dels) do
    <<_::size(n * dbit)-bits, del::size(dbit)-integer-unsigned-big, _::bits>> = dels
    del
  end

  # calculate min and max in a single pass
  @spec minmax([integer(), ...]) :: {integer(), integer()}
  defp minmax([i0 | is]) do
    Enum.reduce(is, {i0, i0}, fn i, {imin, imax} -> {min(i, imin), max(i, imax)} end)
  end
end
