# Used by "mix format"
[
  inputs:
    Enum.flat_map(
      ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
      &Path.wildcard(&1, match_dot: true)
    ) -- ["lib/gfx/space/xform.ex", "lib/gis/location.ex"]
]
