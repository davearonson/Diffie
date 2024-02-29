defmodule Diffie.MixProject do
  use Mix.Project

  def project do
    [
      app: :diffie,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Library for making textual reports, similar to the `diff` command-line
    utility, of the differences between two lists of objects
    (of whatever type), or two strings, broken up on newlines
    (or any other substring).  Also can return a list of differences between
    two lists of objects, as a list rather than a textual report, but still
    marked with not only additions and removals but also _changes_,
    marking the old and new versions.
    """
  end
  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Krzysztof Kempiński"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/kkempin/exiban"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
