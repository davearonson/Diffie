defmodule DiffieTest do
  use ExUnit.Case
  doctest Diffie

  describe "diff_report" do
    test "returns empty for same strings" do
      str = "Same as it ever was,\nsame as it ever was!"
      assert Diffie.diff_report(str, str) == ""
    end

    test "can ignore case" do
      str = "Same as it ever was,\nsame as it ever was!"
      assert Diffie.diff_report(str, String.upcase(str), ignore_case: true) == ""
    end

    test "detects inserted lines" do
      part_1 = "One is the loneliest number\nthat you'll ever do."
      insert = "You put your\nleft foot in..."
      part_2 = "It takes two, baby,\nme and you!"
      str_1 = "#{part_1}\n#{part_2}"
      str_2 = "#{part_1}\n#{insert}\n#{part_2}"
      assert Diffie.diff_report(str_1, str_2) == "Added:\n> #{String.replace(insert, "\n", "\n> ")}"
    end

    test "detects removed lines" do
      part_1 = "One is the loneliest number\nthat you'll ever do."
      remove = "You take your\nleft foot out..."
      part_2 = "It takes two, baby,\nme and you!"
      str_1 = "#{part_1}\n#{remove}\n#{part_2}"
      str_2 = "#{part_1}\n#{part_2}"
      assert Diffie.diff_report(str_1, str_2) == "Removed:\n< #{String.replace(remove, "\n", "\n< ")}"
    end

    test "detects inserted AND removed lines" do
      part_1 = "One is the loneliest number\nthat you'll ever do."
      insert = "You put your\nleft foot in..."
      part_2 = "It takes two, baby,\nme and you!"
      remove = "You take your\nleft foot out..."
      part_3 = "Gimme three steps\ngimme three steps mister..."
      str_1 = "#{part_1}\n#{part_2}\n#{remove}\n#{part_3}"
      str_2 = "#{part_1}\n#{insert}\n#{part_2}\n#{part_3}"
      assert Diffie.diff_report(str_1, str_2) == "Added:\n> #{String.replace(insert, "\n", "\n> ")}\n\nRemoved:\n< #{String.replace(remove, "\n", "\n< ")}"
    end

    test "detects changed lines" do
      old = "When I get older,\nlosing my hair..."
      new = "I got a\nnew attitude!"
      part_1 = "One is the loneliest number\nthat you'll ever do."
      part_2 = "It takes two, baby,\nme and you!"
      str_1 = "#{part_1}\n#{old}\n#{part_2}"
      str_2 = "#{part_1}\n#{new}\n#{part_2}"
      assert Diffie.diff_report(str_1, str_2) == """
      Changed:
      < #{String.replace(old, "\n", "\n< ")}

      Into:
      > #{String.replace(new, "\n", "\n> ")}
      """ |> String.trim("\n")
    end

    test "omits originals of changed lines if asked" do
      old = "When I get older,\nlosing my hair..."
      new = "I got a\nnew attitude!"
      part_1 = "One is the loneliest number\nthat you'll ever do."
      part_2 = "It takes two, baby,\nme and you!"
      str_1 = "#{part_1}\n#{old}\n#{part_2}"
      str_2 = "#{part_1}\n#{new}\n#{part_2}"
      assert Diffie.diff_report(str_1, str_2, omit_deletes: true) == """
      Into:
      > #{String.replace(new, "\n", "\n> ")}
      """ |> String.trim("\n")
    end

    test "uses the right splitter" do
      sep = "whatever"
      part_1 = "One is the loneliest number#{sep}that you'll ever do."
      insert = "You put your#{sep}left foot in..."
      part_2 = "It takes two, baby,#{sep}me and you!"
      str_1 = "#{part_1}#{sep}#{part_2}"
      str_2 = "#{part_1}#{sep}#{insert}#{sep}#{part_2}"
      assert Diffie.diff_report(str_1, str_2, split_on: sep) ==
             "Added:\n> #{String.replace(insert, sep, "\n> ")}"
    end

    test "applies the transform function, to each change separately" do
      part_1 = "One is the loneliest number\nthat you'll ever do."
      insert = "You put your\nleft foot in..."
      expected_insert =
        insert
        |> String.split("\n")
        |> Enum.map(&String.reverse/1)
        |> Enum.join("\n> ")
      part_2 = "It takes two, baby,\nme and you!"
      str_1 = "#{part_1}\n#{part_2}"
      str_2 = "#{part_1}\n#{insert}\n#{part_2}"
      assert Diffie.diff_report(str_1, str_2, transform: &String.reverse/1) == "Added:\n> #{expected_insert}"
    end
  end

end
