[
  {:exa_core, [git: "https://github.com/red-jade/exa_core.git", tag: "v0.3.3"]},
  {:exa_space,
   [git: "https://github.com/red-jade/exa_space.git", tag: "v0.3.5"]},
  {:dialyxir, "~> 1.0", [only: [:dev, :test], runtime: false]},
  {:ex_doc, "~> 0.30", [only: [:dev, :test], runtime: false]},
  {:benchee, "~> 1.0", [only: [:dev, :test], runtime: false]}
]