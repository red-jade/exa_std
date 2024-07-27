defmodule Exa.Std.YazlTest do
  use ExUnit.Case
  import Exa.Std.Yazl

  doctest Exa.Std.Yazl

  test "construct" do
    assert {[], []} = new()

    x = [1, 2, 3]

    assert {[], x} == new(x)
    assert {[], x} == new(x, :endl)
    assert {[], x} == new(x, 0)
    assert {[], x} == new(x, -2)

    assert {[1], [2, 3]} = new(x, 1)
    assert {[2, 1], [3]} = new(x, 2)
    assert {[3, 2, 1], []} = new(x, 99)
    assert {[3, 2, 1], []} = new(x, :endr)

    assert x == x |> new() |> to_list()
    assert x == x |> new(:endl) |> to_list()
    assert x == x |> new(0) |> to_list()

    assert x == x |> new(1) |> to_list()
    assert x == x |> new(2) |> to_list()
    assert x == x |> new(:endr) |> to_list()

    y = [4, 5]
    assert {[], []} = from_lists([], [])
    assert {[3, 2, 1], []} = from_lists(x, [])
    assert {[], [4, 5]} = from_lists([], y)
  end

  test "reverse" do
    x = [1, 2, 3, 4]

    z = new(x)
    assert x == to_list(z)
    assert {[], x} == z
    assert {x, []} = reverse(z)
    assert Enum.reverse(x) == to_list(reverse(z))

    z = new(x, :endr)
    assert x == to_list(z)
    assert {Enum.reverse(x), []} == z
    assert {[], Enum.reverse(x)} == reverse(z)
    assert Enum.reverse(x) == to_list(reverse(z))

    z = new(x, 2)
    assert x == to_list(z)
    assert {[2, 1], [3, 4]} == z
    assert {[3, 4], [2, 1]} == reverse(z)
    assert Enum.reverse(x) == to_list(reverse(z))
  end

  test "query" do
    empty = new()
    assert is_yazl(empty)
    assert 0 == size(empty)
    assert :endr == pos(empty)
    assert :endr == get(empty)
    assert :endl == pos(empty, :ldir)
    assert :endl == get(empty, :ldir)
    assert [] == gets(empty, 0)

    x = [1, 2, 3, 4, 5]
    z = new(x, 3)
    assert {[3, 2, 1], [4, 5]} == z

    assert is_yazl(z)
    assert 5 == size(z)
    assert x == to_list(z)
    assert 3 == pos(z)
    assert 4 == get(z)
    assert 2 == pos(z, :ldir)
    assert 3 == get(z, :ldir)

    assert [] == gets(z, 0)
    assert [4] == gets(z, 1)
    assert [4, 5] == gets(z, 2)
    assert :endr == gets(z, 3)
    assert [3] == gets(z, -1)
    assert [2, 3] == gets(z, -2)
    assert [1, 2, 3] == gets(z, -3)
    assert :endl == gets(z, -4)

    assert [] == gets(z, 0, :ldir)
    assert [3] == gets(z, 1, :ldir)
    assert [2, 3] == gets(z, 2, :ldir)
    assert [1, 2, 3] == gets(z, 3, :ldir)
    assert :endl == gets(z, 4, :ldir)
    assert [4] == gets(z, -1, :ldir)
    assert [4, 5] == gets(z, -2, :ldir)
    assert :endr == gets(z, -3, :ldir)
  end

  test "move" do
    empty = new()
    assert :endr == pos(empty)
    assert empty == move(empty, :ldir)
    assert empty == move(empty, :rdir)

    x = [1, 2, 3, 4, 5]
    z = new(x)
    assert 0 = pos(z)
    assert {[], [1, 2, 3, 4, 5]} == z

    z = move(z, :rdir)
    assert 1 == pos(z)
    assert {[1], [2, 3, 4, 5]} == z

    z = moves(z, 2, :rdir)
    assert 3 == pos(z)
    assert {[3, 2, 1], [4, 5]} == z

    assert z = moves(z, 2, :rdir)
    assert :endr == pos(z)
    assert {[5, 4, 3, 2, 1], []} == z

    assert z == move(z, :rdir)

    z = move(z, :ldir)
    assert 4 == pos(z)
    assert {[4, 3, 2, 1], [5]} == z

    z = moves(z, -3, :rdir)
    assert 1 == pos(z)
    assert {[1], [2, 3, 4, 5]} == z

    z = move(z, :ldir)
    assert 0 == pos(z)
    assert {[], [1, 2, 3, 4, 5]} == z

    assert z == move(z, :ldir)
  end

  test "move_to" do
    empty = new()
    assert :endr == pos(empty)
    assert empty == move_to(empty, :endl)
    assert empty == move_to(empty, :endr)
    assert empty == move_to(empty, 99)

    x = [1, 2, 3, 4, 5]
    z = new(x)
    assert {[], x} == z

    assert z == move_to(z, :endl)
    assert z == move_to(z, 0)

    assert {[1], [2, 3, 4, 5]} == move_to(z, 1)
    assert {[2, 1], [3, 4, 5]} == move_to(z, 2)
    assert {[3, 2, 1], [4, 5]} == move_to(z, 3)
    assert {[4, 3, 2, 1], [5]} == move_to(z, 4)

    assert {[5, 4, 3, 2, 1], []} == move_to(z, 5)
    assert {[5, 4, 3, 2, 1], []} == move_to(z, 99)
    assert {[5, 4, 3, 2, 1], []} == move_to(z, :endr)

    z = new(x, 2)
    assert {[2, 1], [3, 4, 5]} == z

    assert {[], x} == move_to(z, :endl)
    assert {[], x} == move_to(z, 0)

    assert {[1], [2, 3, 4, 5]} == move_to(z, 1)
    assert {[2, 1], [3, 4, 5]} == move_to(z, 2)
    assert {[3, 2, 1], [4, 5]} == move_to(z, 3)
    assert {[4, 3, 2, 1], [5]} == move_to(z, 4)

    assert {[5, 4, 3, 2, 1], []} == move_to(z, 5)
    assert {[5, 4, 3, 2, 1], []} == move_to(z, 99)
    assert {[5, 4, 3, 2, 1], []} == move_to(z, :endr)

    # TODO - move_until
  end

  test "find" do
    x = [1, 2, 3, 4, 5]
    z = new(x)

    assert :endr == find(z, 99, :rdir)
    assert :endl == find(z, 1, :ldir)
    assert :endl == find(z, 5, :ldir)

    z = find(z, 3, :rdir)
    assert {[2, 1], [3, 4, 5]} == z

    assert z == find(z, 3, :rdir)
    assert :endl == find(z, 3, :ldir)

    assert {[3, 2, 1], [4, 5]} == find(z, 4, :rdir)
    assert {[2, 1], [3, 4, 5]} == find(z, 2, :ldir)
    assert {[1], [2, 3, 4, 5]} == find(z, 1, :ldir)
    assert {[4, 3, 2, 1], [5]} == find(z, 5, :rdir)
  end

  test "finds" do
    x = [1, 2, 3, 4, 5]
    z = x |> new() |> find(3)
    assert {[2, 1], [3, 4, 5]} == z

    assert z == finds(z, [])
    assert z == finds(z, [3])
    assert z == finds(z, [3, 4])
    assert z == finds(z, [3, 4, 5])
    assert :endr == finds(z, [3, 4, 5, 6])
    assert :endr == finds(z, [:foo])

    assert z == finds(z, [], :ldir)
    assert z == finds(z, [2], :ldir)
    assert z == finds(z, [1, 2], :ldir)
    assert :endl == finds(z, [0, 1, 2], :ldir)

    assert {[3, 2, 1], [4, 5]} == finds(z, [4, 5])
    assert {[3, 2, 1], [4, 5]} == finds(z, [4])
    assert :endr == finds(z, [5, 6])

    assert {[1], [2, 3, 4, 5]} == finds(z, [1], :ldir)
    assert :endl == finds(z, [1, 0], :ldir)

    x = [1, 2, 3, 3, 3]
    z = new(x)
    assert {[2, 1], [3, 3, 3]} == finds(z, [3])
    assert {[2, 1], [3, 3, 3]} == finds(z, [3, 3])
    assert {[2, 1], [3, 3, 3]} == finds(z, [3, 3, 3])
    assert :endr == finds(z, [3, 3, 3, 3])
  end

  test "set" do
    x = [1, 2, 3, 4, 5]
    z = new(x, 2)
    assert {[2, 1], [3, 4, 5]} == z

    assert {[2, 1], [9, 4, 5]} == set(z, 9, :rdir)
    assert {[9, 1], [3, 4, 5]} == set(z, 9, :ldir)

    z = move_to(z, :endr)
    assert {[5, 4, 3, 2, 1], []} == z
    assert :endr == set(z, 9, :rdir)

    z = move_to(z, :endl)
    assert {[], [1, 2, 3, 4, 5]} == z
    assert :endl == set(z, 9, :ldir)
  end

  test "sets" do
    x = [1, 2, 3, 4, 5]
    z = new(x, 2)
    assert {[2, 1], [3, 4, 5]} == z

    assert {[2, 1], [9, 4, 5]} == sets(z, [9], :rdir)
    assert {[2, 1], [9, 8, 5]} == sets(z, [9, 8], :rdir)
    assert {[2, 1], [9, 8, 7]} == sets(z, [9, 8, 7], :rdir)
    assert :endr == sets(z, [9, 8, 7, 6], :rdir)

    assert {[9, 1], [3, 4, 5]} == sets(z, [9], :ldir)
    assert {[8, 9], [3, 4, 5]} == sets(z, [9, 8], :ldir)
    assert :endl == sets(z, [9, 8, 7], :ldir)
  end

  test "insert" do
    x = [1, 2, 3, 4, 5]
    z = new(x, 2)
    assert {[2, 1], [3, 4, 5]} == z

    assert {[2, 1], [9, 3, 4, 5]} == insert(z, 9, :rdir)
    assert {[9, 2, 1], [3, 4, 5]} == insert(z, 9, :ldir)

    assert {[2, 1], [3, 4, 5, 9]} == insert(z, 9, :endr)
    y = move_to(z, :endr)
    assert {[5, 4, 3, 2, 1], []} == y
    assert {[5, 4, 3, 2, 1], [9]} == insert(y, 9, :rdir)
    assert {[9, 5, 4, 3, 2, 1], []} == insert(y, 9, :ldir)
    assert {[5, 4, 3, 2, 1, 9], []} == insert(y, 9, :endl)

    assert {[2, 1, 9], [3, 4, 5]} == insert(z, 9, :endl)
    x = move_to(z, :endl)
    assert {[], [1, 2, 3, 4, 5]} == x
    assert {[9], [1, 2, 3, 4, 5]} == insert(x, 9, :ldir)
    assert {[], [9, 1, 2, 3, 4, 5]} == insert(x, 9, :rdir)
    assert {[], [1, 2, 3, 4, 5, 9]} == insert(x, 9, :endr)
  end

  test "inserts" do
    x = [1, 2, 3, 4, 5]
    z = new(x, 2)
    assert {[2, 1], [3, 4, 5]} == z

    assert {[2, 1], [8, 9, 3, 4, 5]} == inserts(z, [8, 9], :rdir)
    assert {[9, 8, 2, 1], [3, 4, 5]} == inserts(z, [8, 9], :ldir)

    assert {[2, 1], [3, 4, 5, 8, 9]} == inserts(z, [8, 9], :endr)
    y = move_to(z, :endr)
    assert {[5, 4, 3, 2, 1], []} == y
    assert {[5, 4, 3, 2, 1], [8, 9]} == inserts(y, [8, 9], :rdir)
    assert {[9, 8, 5, 4, 3, 2, 1], []} == inserts(y, [8, 9], :ldir)
    assert {[5, 4, 3, 2, 1, 9, 8], []} == inserts(y, [8, 9], :endl)

    assert {[2, 1, 9, 8], [3, 4, 5]} == inserts(z, [8, 9], :endl)
    x = move_to(z, :endl)
    assert {[], [1, 2, 3, 4, 5]} == x
    assert {[9, 8], [1, 2, 3, 4, 5]} == inserts(x, [8, 9], :ldir)
    assert {[], [8, 9, 1, 2, 3, 4, 5]} == inserts(x, [8, 9], :rdir)
    assert {[], [1, 2, 3, 4, 5, 8, 9]} == inserts(x, [8, 9], :endr)
  end

  test "delete" do
    x = [1, 2, 3, 4, 5]
    z = new(x, 2)
    assert {[2, 1], [3, 4, 5]} == z

    y = delete(z, :rdir)
    assert {[2, 1], [4, 5]} == y
    y = delete(y, :rdir)
    assert {[2, 1], [5]} == y
    y = delete(y, :rdir)
    assert {[2, 1], []} == y
    y = delete(y, :rdir)
    assert :endr == y

    y = delete(z, :ldir)
    assert {[1], [3, 4, 5]} == y
    y = delete(y, :ldir)
    assert {[], [3, 4, 5]} == y
    y = delete(y, :ldir)
    assert :endl == y
  end
end
