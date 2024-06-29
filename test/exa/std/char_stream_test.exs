defmodule Exa.Std.CharStreamTest do
  use ExUnit.Case
  import Exa.Std.CharStream

  doctest Exa.Std.CharStream

  @lorem ~s"""
  Lorem      ipsum  \t dolor-ing sit's   amet, 
  consectetur adipiscing elit. 
  Mauris egestas nisi eget; sapien commodo semper! 
  Nunc volutpat: velit eu - erat euismod, 
  quis pharetra? eros pharetra. 
  """

  @tokens [
    {"lorem", {1, 1, 1}},
    {"ipsum", {1, 12, 12}},
    {"doloring", {1, 21, 21}},
    {"sits", {1, 31, 31}},
    {"amet", {1, 39, 39}},
    {"consectetur", {2, 1, 46}},
    {"adipiscing", {2, 13, 58}},
    {"elit", {2, 24, 69}},
    {"mauris", {3, 1, 76}},
    {"egestas", {3, 8, 83}},
    {"nisi", {3, 16, 91}},
    {"eget", {3, 21, 96}},
    {"sapien", {3, 27, 102}},
    {"commodo", {3, 34, 109}},
    {"semper", {3, 42, 117}},
    {"nunc", {4, 1, 126}},
    {"volutpat", {4, 6, 131}},
    {"velit", {4, 16, 141}},
    {"eu", {4, 22, 147}},
    {"erat", {4, 27, 152}},
    {"euismod", {4, 32, 157}},
    {"quis", {5, 1, 167}},
    {"pharetra", {5, 6, 172}},
    {"eros", {5, 16, 182}},
    {"pharetra", {5, 21, 187}}
  ]

  test "simple" do
    assert {:eos, "", {0, 0, 0}} == new("")

    cstr = new("Baz")
    assert {?B, _, {1, 1, 1}} = cstr

    cstr = next(cstr)
    assert {?a, _, {1, 2, 2}} = cstr

    cstr = next(cstr)
    assert {?z, _, {1, 3, 3}} = cstr

    cstr = next(cstr)
    assert {:eos, _, {1, 3, 3}} = cstr
    assert {:eos, _, {1, 3, 3}} = next(cstr)
  end

  test "lorem" do
    # note the S-sigil removes the margin whitespace
    cstr = new(@lorem)
    assert {?L, _, {1, 1, 1}} = cstr

    cstr = next(cstr)
    assert {?o, _, {1, 2, 2}} = cstr

    {"orem", cstr} = take(cstr, 4)
    assert {?\s, _, {1, 6, 6}} = cstr

    cstr = drop_while(cstr)
    assert {?i, _, {1, 12, 12}} = cstr

    {{"ipsum", {1, 12, 12}}, cstr} = token(cstr)

    {{"doloring", {1, 21, 21}}, cstr} = token(cstr)
    {{"sits", {1, 31, 31}}, cstr} = token(cstr)
    {{"amet", {1, 39, 39}}, cstr} = token(cstr)

    assert {?,, _, {1, 43, 43}} = cstr

    # TODO - newlines
  end

  test "tokenize" do
    toks = tokenize(@lorem)
    assert 25 == length(toks)
    assert @tokens == toks
  end
end
