defmodule RamlParser.RamlTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/raml.js
  """

  use ExSpec, async: true
  import RamlParser

  describe "RAML" do
    it "should report error when remote resource is unavailable" do
      assert_raise(RamlParseError, fn ->
        parse_file!("/404.ERROR")
      end)
    end

    it "should throw its own exception if !include resource is unavailable (RT-260)" do
      str = """
      #%RAML 0.8
      ---
      title: !include 404.ERROR
      """
      assert_raise(RamlParseError, ~r(cannot fetch), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 3
        assert error.column == 8
        raise error
      end)
    end
  end
end
