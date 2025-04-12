# EXA Standard

𝔼𝕏tr𝔸 𝔼li𝕏ir 𝔸dditions (𝔼𝕏𝔸)

EXA project index: [exa](https://github.com/red-jade/exa)

Standard library for new data structures.

Module path: `Exa.Std`

## Features

- Histograms for positive integer labels (IDs)
  - 1D using the Erlang `:array` module
  - General, 2D, 3D sparse histograms using Elixir `Map` module
- Run Length Encoding (RLE):
  - general for lists of any type
  - integers, using lossless binary delta-compression
- Character Stream: incremental char from a binary String with line/column address
- Tidal: managing out-of-order streaming sequence (integer IDs)
- Map of Lists (MoL)
- Map of Sets (MoS)
- Yet Another Zip List (yazl): list with local cursor
- Minimum Heap of key-value pairs (Sorted Map),
  which can also be used as a Priority Queue.

The Minimum Heap is expressed as a protocol,
with three concrete implementations:
- map and minimum-valued index
- ordered list
- complete binary tree

## Building

To bootstrap an `exa_xxx` library build, 
you must run `mix deps.get` twice.

## Benchmarks

Exa uses _Benchee_ for performancee testing.

Test results are stored under `test/bench/*.benchee`.
The current _latest_ baseline and previous results are checked-in.

Run the benchmarks and compare with latest result:

`$ mix test --only benchmark:true`

To run specific benchmark test, for example:

`$ mix test --only benchmark:true test/exa/std/min_heap_test.exs`

## Acknowledgements

Any hand-drawn diagrams are created with [Excalidraw](https://excalidraw.com/)

## EXA License

EXA source code is released under the MIT license.

EXA code and documentation are:<br>
Copyright (c) 2024 Mike French
