defmodule Diffie do
  @moduledoc ~S"""
  Diffie is a module for making human-readable reports of
  the differences between two strings,
  or between two lists of objects (of whatever type).

  NOT FOR DIFFIE-HELLMAN KEY EXCHANGE!
  """

  @doc ~S"""
  `diff_report(old, new, opts \\ %{})`

  `diff_report` returns a string
  containing a report (hence the name),
  similar to a simplified version of the `diff` command-line utility,
  of the differences between the two strings, or two lists.

  Given two strings, by default it works line by line,
  but you can supply a different string (or regex) to split on,
  as `opts[:split_on]`.
  You can also supply a transformation function,
  to be applied to each substring, as `opts[:transform]`.

  Given two _lists_,
  the only option used is `opts[:transform]`.
  If you specify this, then that transformation will be applied to
  each individual changed (added, deleted, replaced, or replacing) item,
  not the _list_ of them.

  If you do _not_ supply a transformation:
  - strings will be handled as-is,
  - items that implement the `String.chars` protocol will be sent to `to_string`,
  - and anything else will be sent to `inspect`.

  If your list items do not implement `String.chars`
  and you wish to apply some transformation,
  that transformation must include turning them into
  something that does, such as piping through `inspect`.

  ## Examples:

  ```
  iex> Diffie.diff_report("foo\nbar", "foo\nbar\nbaz")
  "Added:\n> baz"

  iex> Diffie.diff_report("foo\nbar\nbaz", "foo\nbaz")
  "Removed:\n< bar"

  iex> Diffie.diff_report("foo\nbar\nbaz", "foo\nboo\nbaz")
  "Changed:\n< bar\n\nInto:\n> boo"

  iex> Diffie.diff_report("fooXXbarXXbaz", "fooXXbaz", split_on: "XX")
  "Removed:\n< bar"

  iex> Diffie.diff_report("bar", "baz", split_on: "")
  "Changed:\n< r\n\nInto:\n> z"

  iex> Diffie.diff_report("foo bar\nbaz quux", "fox bear\nbaz quix",
  ...>                    split_on: ~r{\s})
  "Changed:\n< foo\n< bar\n\nInto:\n> fox\n> bear\n\nChanged:\n< quux\n\nInto:\n> quix"

  iex> Diffie.diff_report("foo\nbar\nbaz", "foo\nbaz", transform: &String.upcase/1)
  "Removed:\n< BAR"

  iex> Diffie.diff_report("The quick brown fox jumps\nover the lazy dog.",
  ...>                    "That fox\njumps quickly over\nthe dig!",
  ...>                    split_on: ~r/\s/, transform: &String.upcase/1)
  "Changed:\n< THE\n< QUICK\n< BROWN\n\nInto:\n> THAT\n\nAdded:\n> QUICKLY\n\nChanged:\n< LAZY\n< DOG.\n\nInto:\n> DIG!"

  iex> Diffie.diff_report([1,2], [1,2,3])
  "Added:\n> 3"

  iex> Diffie.diff_report([1,2,3], [1,2])
  "Removed:\n< 3"

  iex> Diffie.diff_report([1,2,3], [1,2,5])
  "Changed:\n< 3\n\nInto:\n> 5"

  iex> Diffie.diff_report([1,2], [1,2,3], transform: fn x->x*2 end)
  "Added:\n> 6"

  iex> alice = %{name: "Alice", age: "29"}
  iex> bob = %{name: "Bob", age: "52"}
  iex> Diffie.diff_report([alice], [alice,bob])
  "Added:\n> %{name: \"Bob\", age: \"52\"}"

  iex> alice = %{name: "Alice", age: "29"}
  iex> bob = %{name: "Bob", age: "52"}
  iex> Diffie.diff_report([alice], [alice, bob],
  ...>                    transform: fn p -> Map.delete(p, :age) end)
  ** (Protocol.UndefinedError) protocol String.Chars not implemented for %{name: "Bob"} of type Map. This protocol is implemented for the following type(s): Atom, BitString, Date, DateTime, Float, Integer, List, NaiveDateTime, Time, URI, Version, Version.Requirement

  iex> alice = %{name: "Alice", age: "29"}
  iex> bob = %{name: "Bob", age: "52"}
  iex> Diffie.diff_report([alice], [alice, bob],
  ...>                    transform: fn p -> Map.delete(p, :age) |> inspect end)
  "Added:\n> %{name: \"Bob\"}"

  iex> alice = %{name: "Alice", age: "29"}
  iex> bob = %{name: "Bob", age: "52"}
  iex> Diffie.diff_report([alice], [alice, bob],
  ...>                    transform: fn p -> p.name end)
  "Added:\n> Bob"
  ```
  """
  def diff_report(old, new, opts \\ %{})

  def diff_report(old_str, new_str, opts)
      when is_binary(old_str) and is_binary(new_str) do
    split_on = opts[:split_on] || "\n"
    diff_report(String.split(old_str, split_on),
                String.split(new_str, split_on),
                opts)
  end

  def diff_report(old_list, new_list, opts)
      when is_list(old_list) and is_list(new_list) do
    List.myers_difference(old_list, new_list)
    |> fix_changes
    |> make_report(opts[:transform])
  end

  # change sequences of "del, ins" nodes (or vice-versa) into "old, new"
  defp fix_changes(results, acc \\ [])
  defp fix_changes([{:del, del},{:ins, ins}|rest], acc) do
    fix_changes(rest, [{:new, ins},{:old, del}|acc])
  end
  defp fix_changes([{:ins, ins},{:del, del}|rest], acc) do
    fix_changes(rest, [{:new, ins},{:old, del}|acc])
  end
  defp fix_changes([head|rest], acc), do: fix_changes(rest, [head|acc])
  defp fix_changes([], acc), do: Enum.reverse(acc)

  defp make_report(results, transform_func, acc \\ [])
  defp make_report([{:eq, _}|rest], tf, acc), do: make_report(rest, tf, acc)
  defp make_report([{comp, items}|rest], transform_func, acc) do
    [word, sym] =
      case comp do
        :del -> ["Removed", "<"]
        :ins -> ["Added", ">"]
        :old -> ["Changed", "<"]
        :new -> ["Into", ">"]
        _    -> ["Unknown comparison '#{comp}'", "?"]
      end
    diffs =
      items
      |> Enum.map(fn item -> "#{sym} #{transform(item, transform_func)}" end)
      |> Enum.join("\n")
    make_report(rest, transform_func, ["#{word}:\n#{diffs}" | acc])
  end
  defp make_report([], _, acc), do: acc |> Enum.reverse |> Enum.join("\n\n")

  defp transform(item, nil) do
    cond do
      is_binary(item)             -> item
      String.Chars.impl_for(item) -> to_string(item)
      true                        -> inspect(item)
    end
  end
  defp transform(item, func), do: func.(item)
end
