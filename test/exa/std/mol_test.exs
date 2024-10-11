defmodule Exa.Std.MolTest do
  use ExUnit.Case
  import Exa.Std.Mol

  doctest Exa.Std.Mol

  test "simple" do
    mol = new() |> add(:foo, 1) |> add(:foo, 2)
    assert 2 == length(mol, :foo)
    assert [2, 1] == get(mol, :foo)

    mol = mol |> append(:foo, 3) |> append(:foo, 1) |> append(:foo, 1)
    assert [2, 1, 3, 1, 1] == get(mol, :foo)

    assert {2, mol} = pick(mol, :foo)
    mol = mol |> add(:bar, 9)

    assert {4, [:foo]} == max_length(mol)
    assert {1, [:bar]} == min_length(mol)
    assert %{1 => [:bar], 4 => [:foo]} = index_length(mol)
    assert 5 == lengths(mol)

    assert [3, 1, 1] == mol |> remove(:foo, 1) |> get(:foo)

    assert [3] == mol |> remove_all(:foo, 1) |> get(:foo)
  end

  test "equality" do
    mol1 = new() |> set(:foo, [3, 1, 3, 4]) |> set(:bar, [1, 1, 2, 2])
    mol2 = new() |> set(:foo, [3, 4, 1, 3]) |> set(:bar, [2, 2, 1, 1])
    assert equal?(mol1, mol2)

    {n, ks} = min_length(mol1)
    assert {4, [:bar, :foo]} == {n, Enum.sort(ks)}
    {n, ks} = max_length(mol2)
    assert {4, [:bar, :foo]} == {n, Enum.sort(ks)}

    mol1 = mol1 |> remove(:bar, 1)
    mol2 = mol2 |> remove(:bar, 2)
    assert not equal?(mol1, mol2)
  end

  test "reverse" do
    mol =
      new()
      |> prepend(:foo, 1)
      |> prepend(:foo, 2)
      |> prepend(:foo, 3)
      |> prepend(:bar, "A")
      |> prepend(:bar, "B")
      |> prepend(:bar, "C")

    assert %{foo: [1, 2, 3], bar: ["A", "B", "C"]} == reverse(mol)
    assert %{foo: [1, 2, 3], bar: ["A", "B", "C"]} == sort(mol)
  end
end
