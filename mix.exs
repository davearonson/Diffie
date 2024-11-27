defmodule Diffie.MixProject do
  use Mix.Project

  def project do
    [
      app: :diffie,
      version: "0.3.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Diffie",
      source_url: "https://github.com/davearonson/diffie/",
      docs: [main: "Diffie", extras: ["README.md"]],
      preferred_cli_env: [muzak: :test]      
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
    Library for making textual reports, similar to a simplified
    `diff` command-line utility, of the differences between
    two strings, or two lists of objects (of whatever type).
    NOT FOR DIFFIE-HELLMAN KEY EXCHANGE!
    """
  end
  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Dave Aronson"],
      licenses: ["BSD-3-Clause"],
      links: %{"GitHub" => "https://github.com/davearonson/diffie"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:muzak, "~> 1.1", only: :test}
    ]
  end
end
