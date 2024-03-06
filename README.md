# Diffie

Diffie is a library for making textual reports,
similar to a simplified version of the `diff` command-line utility,
of the differences between two strings, or two lists of objects.

NOT FOR DIFFIE-HELLMAN KEY EXCHANGE!

The original intended use-case is
to find differences between
two fairly large pieces of text,
such as documentation, reports, or all the visible text on a web page.
I decided to _implement_ that via a helper function that would take lists,
and then decided to expose that version as well,
since it seemed maybe useful but not _too_ far from the original mission.

## Installation

The package can be installed
by adding `diffie` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:diffie, "~> 0.2.0"}
  ]
end
```


## License

3-Clause BSD; see LICENSE file.
