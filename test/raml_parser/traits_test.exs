defmodule RamlParser.TraitsTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/traits.js
  """

  use ExSpec, async: true
  import RamlParser

  describe "Traits" do
    it "should detect unused trait parameters and throw an exception" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      traits:
         - trait1:
             queryParameters:
                 param1:
                     description: <<param1>>
      /:
         get:
             is:
                 - trait1:
                     param1: value1
                     param2: value2
      """
      assert_raise(RamlParseError, ~r(unused parameter: 'param2'), fn ->
        parse_string!(str)
      end)
    end

    it "should detect unused resource type parameters and throw an exception" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      resourceTypes:
         - resourceType1:
             get:
                 queryParameters:
                     param1:
                         description: <<param1>>
      /:
         type:
             resourceType1:
                 param1: value1
                 param2: value2
      """
      assert_raise(RamlParseError, ~r(unused parameter: 'param2'), fn ->
        parse_string!(str)
      end)
    end

    it "should be applied via resource type and parameter key" do
      str = """
      #%RAML 0.8
      ---
      title: Test
      baseUri: http://www.api.com
      resourceTypes:
        - base:
            is: [<<trait>>]
            get:
      traits:
        - trait1:
            description: This is the description of HOL trait.
      /tags:
        type:
          base:
            trait: trait1
        get:
      """
      expected = %{"title" => "Test",
                    "baseUri" => "http://www.api.com",
                    "protocols" => ["HTTP"],
                    "resourceTypes" => [%{"base" => %{"is" => ["<<trait>>"],
                                                      "get" => nil
                                                     }}],
                    "traits" => [%{"trait1" => %{"description" => "This is the description of HOL trait."}}],
                    "resources" => [%{"type" => %{"base" => %{"trait" => "trait1"}},
                                      "relativeUriPathSegments" => ["tags"],
                                      "relativeUri" => "/tags",
                                      "methods" => [%{"description" => "This is the description of HOL trait.",
                                                      "method" => "get",
                                                      "protocols" => ["HTTP"]
                                                     }]
                                     }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should not allow reserved parameters: methodName" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      traits:
         - trait1:
             description: <<methodName>>
      /:
         get:
             is:
               - trait1:
                   methodName: does-not-matter
      """
      assert_raise(RamlParseError, ~r(invalid parameter name: methodName is reserved), fn ->
        parse_string!(str)
      end)
    end

    it "should not allow reserved parameters: resourcePath" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      traits:
         - trait1:
             description: <<resourcePath>>
      /:
         get:
             is:
               - trait1:
                   resourcePath: does-not-matter
      """
      assert_raise(RamlParseError, ~r(invalid parameter name: resourcePath is reserved), fn ->
        parse_string!(str)
      end)
    end

    it "should not crash if applied trait has value of null (RT-364)" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      traits:
         - trait1:
             description: <<resourcePath>>
      /:
         get:
             is:
               - trait1:
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should provide reserved <<resourcePathName>> parameter in URI with no variables" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      traits:
         - trait1:
             description: <<resourcePathName>>
      /a/b/c:
         get:
             is:
               - trait1:
      """
      {:ok, result} = parse_string(str)
      %{"resources" => [%{"methods" => [%{"description" => description} | _]} | _]} = result
      assert description == "c"
    end

    it "should provide reserved <<resourcePathName>> parameter in URI with variables" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      traits:
         - trait1:
             description: <<resourcePathName>>
      /a/b/{c}:
         get:
             is:
               - trait1:
      """
      {:ok, result} = parse_string(str)
      %{"resources" => [%{"methods" => [%{"description" => description} | _]} | _]} = result
      assert description == "b"
    end

    it "should provide reserved <<resourcePathName>> parameter in URI with all variables" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      traits:
         - trait1:
             description: <<resourcePathName>>
      /{a}/{b}/{c}:
         get:
             is:
               - trait1:
      """
      {:ok, result} = parse_string(str)
      %{"resources" => [%{"methods" => [%{"description" => description} | _]} | _]} = result
      assert description == ""
    end

    it "should check for empty trait name provided as a parameter to resource type" do
      str = """
      #%RAML 0.8
      ---
      resourceTypes:
        - resourceType1:
            get:
              is:
                - <<traitName>>
      title: Title
      /:
        type:
          resourceType1:
            traitName:
      """
      assert_raise(RamlParseError, ~r(trait name must be provided), fn ->
        parse_string!(str)
      end)
    end
  end
end
