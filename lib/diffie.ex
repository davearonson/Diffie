defmodule Diffie do
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
    diff_list(old_list, new_list)
    |> make_report(opts[:transform])
  end

  def diff_list(old_list, new_list) do
    List.myers_difference(old_list, new_list)
    |> fix_changes
  end

  # change sequences of "del, ins" nodes (or vice-versa) into "old, new"
  defp fix_changes(results, acc \\ [])
  defp fix_changes([{:del, del},{:ins, ins}|rest], acc) do
    fix_changes(rest, [{:new, ins},{:old, del}|acc])
  end
  defp fix_changes([{:ins, ins},{:del, del}|rest], acc) do
    fix_changes(rest, [{:new, ins},{:old, del}|acc])
  end
  # we could probably dump head here, but future features may need it
  defp fix_changes([head|rest], acc), do: fix_changes(rest, [head|acc])
  defp fix_changes([], acc), do: Enum.reverse(acc)

  defp make_report(results, xform, acc \\ [])
  defp make_report([{:eq, _}|rest], xform, acc), do:
    make_report(rest, xform, acc)
  defp make_report([{comp, items}|rest], xform, acc) do
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
      |> Enum.map(fn item -> "#{sym} #{transform(item, xform)}" end)
      |> Enum.join("\n")
    make_report(rest, xform, ["#{word}:\n#{diffs}" | acc])
  end
  defp make_report([], _, acc), do: acc |> Enum.reverse |> Enum.join("\n\n")

  defp transform(item, nil) do
    cond do
      is_binary(item)             -> item
      String.Chars.impl_for(item) -> to_string(item)
      true                        -> inspect(item)
    end
  end
  defp transform(item, xform), do: xform.(item)
end
