defmodule Diffie do

  def diff_report(old, new, opts \\ %{})

  def diff_report(old, new, opts) when is_binary(old) and is_binary(new) do
    split_on = opts[:split_on] || "\n"
    diff_report(String.split(old, split_on),
                String.split(new, split_on),
                opts)
  end

  def diff_report(old, new, opts) when is_list(old) and is_list(new) do
    diff_list(old, new)
    |> make_report(opts)
  end

  def diff_list(old, new) do
    List.myers_difference(old, new)
    |> fix_changes
  end

  # change sequences of "del, ins" nodes into "old, new",
  # when preceded or followed by an "eq".
  def fix_changes(results, acc \\ [])
  # sequence at start -- no eq on the front.
  # keep the later eq in case it intro's another sequence.
  # logic: it must be either at the start, or after another eq,
  # because if there were an ins or del before it, with no eq,
  # the inserted or deleted string would have been tacked onto
  # this insertion or deletion.
  def fix_changes([{:del, del},{:ins, ins},{:eq, eq}|rest], acc) do
    fix_changes([{:eq, eq}|rest], [{:new, ins},{:old, del}|acc])
  end
  # sequence in the middle or end
  # logic: it must be either at the end, or before another eq,
  # because if there were an ins or del after it, with no eq,
  # the inserted or deleted string would have been tacked onto
  # this insertion or deletion.
  def fix_changes([{:eq, eq},{:del, del},{:ins, ins}|rest], acc) do
    fix_changes(rest, [{:new, ins},{:old, del},{:eq, eq}|acc])
  end
  def fix_changes([head|rest], acc), do: fix_changes(rest, [head|acc])
  def fix_changes([], acc), do: acc |> Enum.reverse

  def make_report(results, opts, acc \\ [])
  def make_report([{:eq, _}|rest], opts, acc), do: make_report(rest, opts, acc)
  def make_report([{comp, items}|rest], opts, acc) do
    transform_func = opts[:transform] || &to_string/1
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
      |> Enum.map(fn item -> "#{sym} #{transform_func.(item)}" end)
      |> Enum.join("\n")
    make_report(rest, opts, ["#{word}:\n#{diffs}" | acc])
  end
  def make_report([], _, acc), do: acc |> Enum.reverse |> Enum.join("\n\n")
end
