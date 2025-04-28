defmodule Diffie do
  @moduledoc ~S"""
  Diffie is a module for making human-readable reports of
  the differences between two strings,
  or between two lists of objects (of whatever type).

  NOT FOR DIFFIE-HELLMAN KEY EXCHANGE!
  """

  @doc ~S"""
  `diff_report(old, new, opts \\ [])`

  `diff_report` returns a string
  containing a report (hence the name),
  similar to a simplified version of the `diff` command-line utility,
  of the differences between the two strings, or two lists.

  Given two strings, by default it works line by line,
  and is case-sensitive,
  but you can change this with options, as follows:

  - `:ignore_case` - (boolean) be case-insensitive when comparing the strings.  Does not get applied to strings _within objects_.  If you want that, you will have to use a custom transformation function (see below).  Also applicable to the version that takes two lists, _if_ you pass it two lists _of strings_.

  - `:omit_deletes` - (boolean) omit deleted items, and old versions of changed items.  Also applicable to the version that takes two lists.  Causes the new version of a changed item to be marked with "Updated" rather than "Into".

  - `:omit_moves` - (boolean) omit moved items.  Also applicable to the version that takes two lists.  At this time this does not work properly in conjunction with `ignore_case`, and it all depends on what `List.myers_difference` sees as the whole added or removed chunk.

  - `:split_on` - (string or regex) split strings on this, not \n.

  - `:transform` - (function reference) function to apply to items in the report.  Also applicable to the version that takes two lists.

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

  iex> Diffie.diff_report("foo\nbar\nbaz", "foo\nboo\nbaz", omit_deletes: true)
  "Updated:\n> boo"  # note removal of "Changed:\n< r\n\n" and different marker

  iex> Diffie.diff_report("foo bar\nbaz quux", "fox bear\nbaz quix",
  ...>                    split_on: ~r{\s})
  "Changed:\n< foo\n< bar\n\nInto:\n> fox\n> bear\n\nChanged:\n< quux\n\nInto:\n> quix"

  iex> Diffie.diff_report("foo\nbar\nbaz", "foo\nbaz", transform: &String.upcase/1)
  "Removed:\n< BAR"

  iex> Diffie.diff_report("The quick brown fox jumps\nover the lazy dog.",
  ...>                    "That fox\njumps quickly over\nthe dig!",
  ...>                    split_on: ~r/\s/, transform: &String.upcase/1)
  "Changed:\n< THE\n< QUICK\n< BROWN\n\nInto:\n> THAT\n\nAdded:\n> QUICKLY\n\nChanged:\n< LAZY\n< DOG.\n\nInto:\n> DIG!"

  iex> Diffie.diff_report("The quick brown fox jumps over the lazy dog.",
  ...>                    "That fox jumps quickly over the dig!",
  ...>                    split_on: ~r/\s/, omit_deletes: true)
  "Updated:\n> That\n\nAdded:\n> quickly\n\nUpdated:\n> dig!"

  iex> Diffie.diff_report("The quick brown fox jumps over the lazy dog",
  ...>                    "That fox jumps quickly",
  ...>                    split_on: ~r/\s/, omit_deletes: true)
  "Updated:\n> That\n\nUpdated:\n> quickly"

  iex> Diffie.diff_report("The quick brown fox jumps over the lazy dog",
  ...>                    "That fox jumps quickly over",
  ...>                    split_on: ~r/\s/, omit_deletes: true)
  "Updated:\n> That\n\nAdded:\n> quickly"

  iex> Diffie.diff_report("alpha bravo charlie delta",
  ...>                    "alpha charlie bravo delta",
  ...>                    split_on: " ", omit_moves: true)
  ""

  iex> Diffie.diff_report([1,2], [1,2,3])
  "Added:\n> 3"

  iex> Diffie.diff_report([1,2,3], [1,2])
  "Removed:\n< 3"

  iex> Diffie.diff_report([1,2,3,4,6], [1,2,5])
  "Changed:\n< 3\n< 4\n< 6\n\nInto:\n> 5"

  iex> Diffie.diff_report([1,2,3,4,6], [1,2,5,6,7], omit_deletes: true)
  "Updated:\n> 5\n\nAdded:\n> 7"  # note removal of "Changed:\n< 3\n\n", and different marker

  iex> Diffie.diff_report([1,2,3], [1,2], omit_deletes: true)
  ""

  iex> Diffie.diff_report([1, 2, 3, 4, 5],
  ...>                    [1, 2, 5, 3, 4],
  ...>                    omit_moves: true)
  ""

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
  def diff_report(old, new, opts \\ [])

  # if it's two binaries, split them (on whatever we're supposed to),
  # and hand the results over to the two-lists version
  def diff_report(old_str, new_str, opts)
      when is_binary(old_str) and is_binary(new_str) do
    split_on = opts[:split_on] || "\n"
    diff_report(String.split(old_str, split_on),
                String.split(new_str, split_on),
                opts)
  end

  def diff_report(old_list, new_list, opts)
      when is_list(old_list) and is_list(new_list) do
    if opts[:ignore_case] && ! (old_list |> hd |> is_binary) do
      "ERROR: you said to ignore case, but the list is not of strings!"
    else
      List.myers_difference(old_list, new_list)
      |> maybe_remove_moves(!!opts[:omit_moves])
      |> fix_diffs(%{ignore_case:  !!opts[:ignore_case],
                     omit_deletes: !!opts[:omit_deletes]},
                   [])
      |> make_report(opts[:transform])
    end
  end

  defp maybe_remove_moves(diffs, false), do: diffs
  defp maybe_remove_moves(diffs, true), do: remove_moves(diffs, diffs, [])

  defp remove_moves([diff={:eq, _}|rest], all_diffs, acc) do
    remove_moves(rest, all_diffs, [diff|acc])
  end
  # TODO: make this work properly with ignore_case!
  # TODO MAYBE EVENTUALLY: make sure it's a 1-1 correspondence
  defp remove_moves([head|rest], all_diffs, acc) do
    target = opposite_action(head)
    if Enum.member?(all_diffs, target) do
      remove_moves(rest, all_diffs, acc)
    else
      remove_moves(rest, all_diffs, [head|acc])
    end
  end
  defp remove_moves([], _all_diffs, acc), do: Enum.reverse(acc)

  defp opposite_action({:del, stuff}), do: {:ins, stuff}
  defp opposite_action({:ins, stuff}), do: {:del, stuff}

  # if we have a del and an ins, process as an update
  defp fix_diffs([del={:del, _}|[ins={:ins, _}|rest]], opts, acc) do
    process_update(rest, opts, del, ins, acc)
  end

  # same if the other way round
  defp fix_diffs([ins={:ins, _}|[del={:del, _}|rest]], opts, acc) do
    process_update(rest, opts, del, ins, acc)
  end

  # else if we have a delete and we're omitting them, just move on
  defp fix_diffs([{:del, _}|rest], opts=%{omit_deletes: true}, acc) do
    fix_diffs(rest, opts, acc)
  end

  # else if we have a delete (since we're not omitting them), do it
  defp fix_diffs([del={:del, _}|rest], opts, acc) do
    fix_diffs(rest, opts, [del|acc])
  end

  # same for insert
  defp fix_diffs([ins={:ins, _}|rest], opts, acc) do
    fix_diffs(rest, opts, [ins|acc])
  end

  # if we have an eq, just move on
  defp fix_diffs([{:eq, _}|rest], opts, acc) do
    fix_diffs(rest, opts, acc)
  end

  # else if end of list, we're done
  defp fix_diffs([], _opts, acc), do: Enum.reverse(acc)

  defp process_update(rest, opts, {:del, dels}, {:ins, inss}, acc) do
    new_acc = cond do
      really_same(dels, inss, opts) ->
        acc
      opts[:omit_deletes] ->
        [{:upd, inss}|acc]
      true ->
        [{:new, inss}|[{:old, dels}|acc]]
    end
    fix_diffs(rest, opts, new_acc)
  end

  defp really_same(same, same, _opts), do: true
  defp really_same(dels, inss, %{ignore_case: true}) do
    if Enum.count(dels) == Enum.count(inss) do
      downcases_match(dels, inss)
    else
      false
    end
  end
  defp really_same(_, _, _), do: false

  defp downcases_match([dhead|drest], [ihead|irest]) do
    if String.downcase(dhead) == String.downcase(ihead) do
      downcases_match(drest, irest)
    else
      false
    end
  end
  defp downcases_match([], []), do: true

  defp make_report(results, transform_func, acc \\ [])
  defp make_report([{:eq, _}|rest], tf, acc), do: make_report(rest, tf, acc)
  defp make_report([{comp, items}|rest], transform_func, acc) do
    [word, sym] =
      case comp do
        :del -> ["Removed", "<"]
        :ins -> ["Added",   ">"]
        :old -> ["Changed", "<"]
        :new -> ["Into",    ">"]
        :upd -> ["Updated", ">"]
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
