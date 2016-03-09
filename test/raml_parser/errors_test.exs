defmodule RamlParser.ErrorsTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/errors.js
  """

  use ExSpec, async: true
  import RamlParser

  describe "Errors" do
    it "should be at right line/column when new document content started without special marker right after end marker" do
      str = """
      #%RAML 0.8
      ---
      title: API 1
      ...
      title: API 2
      """
      assert_raise(RamlParseError, fn ->
        {:error, error} = parse_string(str)
        assert error.line == 5
        assert error.column == 1
        raise error
      end)
    end

    it "should error with non-printable characters and render index correctly" do
      str = """
      #%RAML 0.8
      *Note:* You may provide an optional *scope* parameter to request additional permissions outside of the "basic" permissions scope. [Learn more about scope](http://instagram.com/developer/authentication/#scop
      """
      assert_raise(RamlParseError, fn ->
        {:error, error} = parse_string(str)
        assert error.line == 2
        assert error.column == 111
        raise error
      end)
    end

    it "should render error messages with the correct index" do
      str = """
      #%RAML 0.8
      title: {]
      """
      assert_raise(RamlParseError, fn ->
        {:error, error} = parse_string(str)
        assert error.line == 2
        assert error.column == 9
        raise error
      end)
    end
  end
end
