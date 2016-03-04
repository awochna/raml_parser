defmodule RamlParser.IncludeResolutionTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/includeResolution.js
  """
  'use strict';

  use ExSpec, async: true
  import RamlParser

  describe 'Include resolution injection' do
    it 'should call injected method' do
      str = """
      #%RAML 0.8
      !include test/assets/include.raml
      """
      expected = %{"title" => "Hi"}
      result = parse_string!(str)
      assert result == expected
    end

    it 'should reject if detects circular reference on the first document' do
      str = """
      #%RAML 0.8
      !include test/assets/circular-include.raml
      """
      assert_raise(RamlParseError, ~r(ciruclar include detected), fn ->
        parse_string!(str)
      end)
    end

    it 'should resolve !include tag as an array element' do
      str = """
      #%RAML 0.8
      title: title
      traits:
        - !include test/assets/trait.raml
      """

      expected = %{"title" => "title",
                   "traits" => [
                     %{"trait" => %{}}
                   ]
                  }

      result = parse_string!(str)
      assert result == expected
    end

    it 'should resolve !include tags in proper order' do
      str = """
      #%RAML 0.8
      title: title
      traits:
        - !include test/assets/trait1.raml
        - !include test/assets/trait2.raml
      """

      expected = %{"title" => "title",
                   "traits" => [
                     %{"trait1" => %{}},
                     %{"trait2" => %{}}
                   ]
                  }
      result = parse_string!(str)
      assert result == expected
    end

    it 'should resolve mixed !include tags (in-place and deferred)' do
      str = """
      #%RAML 0.8
      title: title
      traits:
        - trait1: {}
        - !include test/assets/trait2.raml
        - trait3: {}
      """
      expected = %{"title" => "title",
                   "traits" => [
                     %{"trait1" => %{}},
                     %{"trait2" => %{}},
                     %{"trait3" => %{}}
                   ]
                  }
      result = parse_string!(str)
      assert result = expected
    end
  end
end
