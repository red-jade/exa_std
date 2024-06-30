defmodule Exa.Std.CharStream do
  @moduledoc """
  A character stream from a String binary.

  Each character is extracted in turn
  and is made available for pattern matching.

  Each character is located with the current address in the binary:
  - 1-based line number (value 0 means empty stream)
  - 0-based column number (value 0 means previous newline)
  - 0-based character number (absolute, including all newlines)

  The default line break is either:
  - a single `\n` character (Unix)
  - the sequence `\r\n` (Windows)

  The `\r\n` is treated as a single newline, 
  the line count is incremented by 1,
  the character count is incremented by 2,
  and only the `\n` appears in the current position in the stream.

  """
  require Logger
  use Exa.Constants

  import Exa.Types
  alias Exa.Types, as: E

  # -----
  # types
  # -----

  @typedoc "Character address"
  @type caddr() :: {line :: E.index0(), col :: E.index0(), addr :: E.index0()}

  @typedoc "Character or end of stream `:eos`."
  @type schar() :: char() | :eos

  @typedoc "A character stream."
  @type cstream() :: {head :: schar(), tail :: String.t(), addr :: caddr()}

  @typedoc "A token is a string with a starting character address."
  @type token() :: {String.t(), caddr()}

  # TODO - support Unicode line breaks
  # TODO - support Unicode whitespace

  # ---------------
  # public function
  # ---------------

  @doc """
  Create a new character stream.

  An empty string will create an end-of-stream with address `{0,0,0}`.
  """
  @spec new(String.t()) :: cstream()
  def new(<<>>), do: {:eos, <<>>, {0, 0, 0}}
  def new(<<?\r, ?\n, rest::binary>>), do: {?\n, rest, {2, 0, 2}}
  def new(<<?\n, rest::binary>>), do: {?\n, rest, {2, 0, 1}}
  def new(<<c::utf8, rest::binary>>), do: {c, rest, {1, 1, 1}}

  @doc """
  Advance a character stream.

  An end-of-stream will remain end-of-stream.
  """
  @spec next(cstream()) :: cstream()
  def next({_, <<?\r, ?\n, rest::binary>>, {l, _, n}}), do: {?\n, rest, {l + 1, 0, n + 2}}
  def next({_, <<?\n, rest::binary>>, {l, _, n}}), do: {?\n, rest, {l + 1, 0, n + 1}}
  def next({_, <<char::utf8, rest::binary>>, {l, c, n}}), do: {char, rest, {l, c + 1, n + 1}}
  def next({:eos, <<>>, _} = eos), do: eos
  def next({_, <<>>, addr}), do: {:eos, <<>>, addr}

  @doc """
  Advance a character stream skipping over
  characters accepted by an exclude predicate (drop_while).

  The default skip predicate is for ASCII whitespace.

  An end-of-stream will remain end-of-stream.
  """
  @spec drop_while(cstream(), E.predicate?(char())) :: cstream()
  def drop_while(cstr, skip \\ &is_ws/1)

  def drop_while({:eos, <<>>, _} = eos, _skip), do: eos

  def drop_while({c, _, _} = cstr, skip) do
    cond do
      skip.(c) -> cstr |> next() |> drop_while(skip)
      true -> cstr
    end
  end

  @doc """
  Advance a character stream by a fixed number of characters.
  The count applies to the head tail of the stream,
  ignoring the current head character.

  Return the token taken from the stream.

  An end-of-stream will remain end-of-stream
  and the returned token will be truncated at the end of the stream.
  """
  @spec take(cstream(), pos_integer()) :: {String.t(), cstream()}
  def take(cstr, n \\ 1) do
    Enum.reduce(1..n, {"", cstr}, fn
      _i, {out, {:eos, _, _} = eos} -> {out, eos}
      _i, {out, {c, _, _} = cstr} -> {<<out::binary, c::utf8>>, next(cstr)}
    end)
  end

  @doc """
  Take a token from the head of the stream.

  Initially ignore characters according to a skip predicate (drop_while),
  then take a token from the head of the stream,
  according to a include predicate (take_while) 
  and an exclude predicate (ignore filter).

  The token will end when the current head character 
  is _false_ for both inclusion and exclusion.

  Return the token taken from the stream.
  The token string is downcased.
  The token includes the starting address in the stream.

  The default skip predicate is ASCII whitespace.

  The default inclusion predicate is ASCII alpha-numeric.

  The default exclusion predicate is to ignore `'` and `-` connectives,
  which has the effect of merging English language elisions,
  possessives and hyphenations
  (e.g. _isn't → isnt, John's → Johns, James' → James, check-in → checkin_ )

  An end-of-stream will remain end-of-stream
  and the returned token will be truncated at the end of the stream.
  The token contain the empty string "".
  """
  @spec token(cstream(), E.predicate?(char()), E.predicate?(char()), E.predicate?(char())) ::
          {token(), cstream()}
  def token({_, _, addr} = cstr, skip \\ &is_ws/1, incl \\ &is_alphanum/1, excl \\ &is_connect/1) do
    cstr |> drop_while(skip) |> tok(incl, excl, "", addr)
  end

  defp tok({:eos, _, _} = eos, _incl, _excl, str, addr), do: {{str, addr}, eos}

  defp tok({c, _, iaddr} = cstr, incl, excl, str, addr) do
    cond do
      # record the addr for the first included character
      incl.(c) ->
        c = Exa.String.downcase(c)

        case str do
          "" -> tok(next(cstr), incl, excl, <<c::utf8>>, iaddr)
          _ -> tok(next(cstr), incl, excl, <<str::binary, c::utf8>>, addr)
        end

      excl.(c) ->
        tok(next(cstr), incl, excl, str, addr)

      true ->
        {{str, addr}, cstr}
    end
  end

  @doc """
  Tokenize a String.

  The rules are the same as for `token`,
  but the default skip predicate now also includes 
  common phrase or sentence delimiters: `,`, `.`, `;`, `:`, `!`, `?`
  and `-` separated by whitespace (i.e. not an internal hyphenation).
  """
  @spec tokenize(String.t(), E.predicate?(char()), E.predicate?(char()), E.predicate?(char())) ::
          [token()]
  def tokenize(str, skip \\ &is_ws_delim/1, incl \\ &is_alphanum/1, excl \\ &is_connect/1) do
    str |> new() |> toks(skip, incl, excl, [])
  end

  defp toks(cstr, skip, incl, excl, toks) do
    case token(cstr, skip, incl, excl) do
      {{"", _}, {:eos, _, _}} ->
        Enum.reverse(toks)

      {tok, {:eos, _, _}} ->
        Enum.reverse([tok | toks])

      {tok, new_cstr} when new_cstr != cstr ->
        toks(new_cstr, skip, incl, excl, [tok | toks])

      {_tok, {c, _, {line, col, _}}} ->
        msg = "[#{line}, #{col}] Illegal character '#{<<c::utf8>>}'"
        Logger.error(msg)
        raise ArgumentError, message: msg
    end
  end

  # -----------------
  # private functions
  # -----------------

  # test for ASCII white space, or common phrase or sentence delimiters
  @spec is_ws_delim(char()) :: bool()
  defp is_ws_delim(c), do: is_ws(c) or c in ~c",.;:!?-\""

  # test for common internal connectives
  @spec is_connect(char()) :: bool()
  defp is_connect(c), do: c in ~c"'-"
end
