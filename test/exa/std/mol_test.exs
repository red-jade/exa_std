defmodule Exa.Std.MolTest do
  use ExUnit.Case
  import Exa.Std.Mol

  doctest Exa.Std.Mol

  test "simple" do
    mol = new() |> add(:foo, 1) |> add(:foo, 2)
    assert 2 == length(mol, :foo)
    assert [2, 1] = get(mol, :foo)

    mol = mol |> append(:foo, 3) |> append(:foo, 1) |> append(:foo, 1)
    assert [2, 1, 3, 1, 1] = get(mol, :foo)

    assert {:ok, 2, mol} = take_hd(mol, :foo)
    mol = mol |> add(:bar, 9)

    assert 5 == lengths(mol)

    assert [3, 1, 1] = mol |> remove(:foo, 1) |> get(:foo)

    assert [3] = mol |> remove_all(:foo, 1) |> get(:foo)
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
