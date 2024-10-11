defmodule Exa.Std.HistoTest do
  use ExUnit.Case

  import Exa.Std.Histo

  test "simple" do
    h = new()
    assert {0, []} = min_count(h)
    assert {0, []} = max_count(h)

    h = inc(h, :foo)
    assert {1, [:foo]} = min_count(h)
    assert {1, [:foo]} = max_count(h)

    h = inc(h, :foo)
    assert %{:foo => 2}

    assert {2, [:foo]} = min_count(h)
    assert {2, [:foo]} = max_count(h)

    h = inc(h, :bar)
    assert %{:foo => 2, :bar => 1}
    assert {1, [:bar]} = min_count(h)
    assert {2, [:foo]} = max_count(h)
  end
end
