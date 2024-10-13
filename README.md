# EXA Standard

𝔼𝕏tr𝔸 𝔼li𝕏ir 𝔸dditions (𝔼𝕏𝔸)

EXA project index: [exa](https://github.com/red-jade/exa)

Standard library for new data structures.

Module path: `Exa.Std`

## Features

- Histograms for positive integer labels (IDs)
  - 1D using the Erlang `:array` module
  - Geeral, 2D, 3D sparse histograms using Elixir `Map` module
- Run Length Encoding (RLE):
  - general for lists of any type
  - integers, using lossless binary delta-compression
- Character Stream: incremental char from a binary String with line/column address
- Tidal: managing out-of-order streaming sequence (integer IDs)
- Map of Lists (MoL)
- Map of Sets (MoS)
- Yet Another Zip List (yazl): list with local cursor

## Building

To bootstrap an `exa_xxx` library build, 
you must run `mix deps.get` twice.

## Acknowledgements

Any hand-drawn diagrams are created with [Excalidraw](https://excalidraw.com/)

## EXA License

EXA source code is released under the MIT license.

EXA code and documentation are:<br>
Copyright (c) 2024 Mike French
