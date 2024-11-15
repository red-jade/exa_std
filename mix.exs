defmodule Exa.Std.MixProject do
  use Mix.Project

  @lib :exa_std
  @name "Exa Std"
  @ver "0.3.2"

  def project do
    [
      app: @lib,
      name: @name,
      version: @ver,
      elixir: "~> 1.17",
      erlc_options: [:verbose, :report_errors, :report_warnings, :export_all],
      start_permanent: Mix.env() == :prod,
      deps: exa_deps() ++ local_deps(),
      docs: docs(),
      test_pattern: "*_test.exs",
      dialyzer: [flags: [:no_improper_lists]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "readme",
      output: "doc/api",
      assets: %{"assets" => "assets"},
      extras: ["README.md"]
    ]
  end

  defp exa_libs() do
    [
      :exa_core,
      :exa_space,
      :dialyxir,
      :ex_doc
    ]
  end

  defp local_deps() do
    []
  end

  # ------------------
  # EXA umbrella build 
  # ------------------

  # umbrella project
  @exa {:exa,
        git: "https://github.com/red-jade/exa.git",
        branch: "main",
        only: [:dev, :test],
        runtime: false}

  # dependency config code
  @mix_util Path.join(["deps", "exa", "mix_util.ex"])

  defp exa_deps() do
    cond do
       arg_scope() == :rel -> 
        # read auto-generated deps file
        "deps.ex" |> Code.eval_file() |> elem(0) 

      File.regular?(@mix_util) ->
        # generate deps using exa umbrella project
        if not Code.loaded?(Exa.MixUtil) do
          [{Exa.MixUtil, _}] = Code.compile_file(@mix_util)
        end

        Exa.MixUtil.exa_deps(@lib, exa_libs())
      true ->
        # bootstrap from exa umbrella project
        [@exa]
      end
  end

  # get scope from env var or cmd line
  # return atom, default to :rel
  defp arg_scope() do
    default =
      case System.fetch_env("EXA_BUILD") do
        :error -> "rel"
        {:ok, mix_build} -> mix_build
      end

    System.argv()
    |> tl()
    |> OptionParser.parse(strict: [build: :string])
    |> elem(0)
    |> Keyword.get(:build, default)
    |> String.to_atom()
  end
end
