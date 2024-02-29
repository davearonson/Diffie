# Diffie

Diffie is a module mainly for making human-readable reports of
the differences between two lists of objects (of whatever type),
or two strings.&nbsp;
It also can detect `del`-`ins` pairs,
in the output of `List.myers_difference`, that actually mean that
something has been _changed_, rather than inserted or removed.


## Functions


`diff_report(old_str, new_str, opts \\ %{})`

Given two strings, `diff_report` returns a string
containing a report (hence the name),
similar to a simplified version of the `diff` command-line utility,
of the differences between the two strings.&nbsp;
By default, it works line by line,
but you can supply a different string to split on, as `opts[:split_on]`.&nbsp;
You can also supply a transformation function,
to be applied to each substring, as `opts[:transform]`.

Examples:

```
iex> IO.puts Diffie.diff_report("foo\nbar", "foo\nbar\nbaz")
Added:
> baz
:ok

iex> IO.puts Diffie.diff_report("foo\nbar\nbaz", "foo\nbaz")
Removed:
< bar
:ok

iex> IO.puts Diffie.diff_report("foo\nbar\nbaz", "foo\nboo\nbaz")
Changed:
< bar

Into:
> boo
:ok

iex> IO.puts Diffie.diff_report("fooXbarXbaz", "fooXbaz", split_on: "X")
Removed:
< bar
:ok

iex> IO.puts Diffie.diff_report("foo\nbar\nbaz", "foo\nbaz", transform: &String.upcase/1)
Removed:
< BAR
:ok

```


`diff_report(old_list, new_list, opts \\ %{})`

Given two _lists_, `diff_report` returns a string
containing a report (hence the name),
similar to a simplified version of the `diff` command-line utility,
of the differences between the two lists.

The only option used at this time is `opts[:transform]`.&nbsp;
If you specify this, then that transformation will be applied to
each change (insertion, deletion, or change from an old to new value).&nbsp;
If you do _not_ supply a transformation:
- strings will be handled as-is,
- items that implement the `String.chars` protocol will be sent to `to_string`,
- and anything else will be sent to `inspect`.

You can also use this to apply other transformations,
such as reversing and/or upcasing/downcasing a string,
or adding, removing, or retrieving just certain fields from a `Map`.

Examples:

```
iex> IO.puts Diffie.diff_report([1,2], [1,2,3])
Added:
> 3
:ok

iex> IO.puts Diffie.diff_report([1,2,3], [1,2])
Removed:
< 3
:ok

iex> IO.puts Diffie.diff_report([1,2,3], [1,2,5])
Changed:
< 3

Into:
> 5
:ok

iex> IO.puts Diffie.diff_report([1,2], [1,2,3], transform: fn x->x*2 end)
Added:
> 6
:ok

iex> alice = %{name: "Alice", age: "29"}
iex> bob = %{name: "Bob", age: "52"}
iex> IO.puts Diffie.diff_report([alice], [alice,bob])
Added:
> %{name: "Bob", age: "52"}
:ok
```

If your items do not implement `String.chars`
and you wish to apply some transformation,
that transformation must include turning them into
something that does.&nbsp;
For example:

```
iex> IO.puts Diffie.diff_report([alice], [alice, bob],
...> transform: fn p -> Map.delete(p, :age) end)
** (Protocol.UndefinedError) protocol String.Chars not implemented for %{name: "Bob"} of type Map.

# if we just pipe that through inspect, so we get a string, it all works.

iex> IO.puts Diffie.diff_report([alice], [alice, bob],
...> transform: fn p -> Map.put(p, :foo, 42) |> inspect end)
Added:
> %{name: "Bob"}
:ok

# or we can change our transform to something that inherently yields a string

iex> IO.puts Diffie.diff_report([alice], [alice, bob], transform: fn p -> p.name end)
Added:
> Bob
:ok
```


`diff_list(old_list, new_list)`

Return a list of the differences between the two lists.&nbsp;
Unlike the return value of `List.myers_difference`,
it uses tags not only `del`, `ins`, and `eq`, but also `new` and `old`,
to indicate what has been _changed_, from the old form to the new.&nbsp;
(This is really just a call to `List.myers_difference`, piped through
a function to detect those `del`-`ins` pairs that actually mean that
something has been changed.)

Unlike `diff_report`, this doesn't care about
the "stringiness" of your list items,
so it does not take a `transform:` function,
nor does it need anything to `split_on:`,
so there are no options.&nbsp;

Example:

```
iex> Diffie.diff_list([1,1,2,3,5,8,13], [2,3,5,7,11,13])
[del: [1, 1], eq: [2, 3, 5], old: ~c"\b", new: ~c"\a\v", eq: ~c"\r"]
```

That may look weird but it's because of how `iex` ass-u-me's
that numbers below 128 may represent characters,
so lists of them are charlists.&nbsp;
Don't get me started.&nbsp;
We can show what the above is equivalent to in numbers, as follows:

```
iex> Diffie.diff_list([1,1,2,3,5,8,13], [2,3,5,7,11,13]) ==
...> [del: [1, 1], eq: [2, 3, 5], old: [8], new: [7, 11], eq: [13]]
true
```


## Installation


If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `diffie` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:diffie, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/diffie>.
