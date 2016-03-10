defmodule RamlParser.ResourceTypesTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/resourceTypes.js
  """

  use ExSpec, async: true
  import RamlParser

  describe "Resource Types" do
    it "should report an error with better message when circular reference is detected" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      resourceTypes:
         - a:
             description: Resource type A
             type: b
         - b:
             description: Resource type B
             type: c
         - c:
             description: Resource type C
             type: a
      /:
         type: a
      """
      assert_raise(RamlParseError, ~r(circular reference of 'a' has been detected: a -> b -> c -> a), fn ->
        parse_string!(str)
      end)
    end

    it "should inherit properties when applied with parameters at at least second level (RT-295)" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      resourceTypes:
         - a:
             get:
                 description: Hello, <<name>>
         - b:
             type:
                 a:
                     name: John Galt
      /:
         type: b
      """
      expected = %{"title" => "Title",
                   "resourceTypes" => [%{"a" => %{"get" => %{"description" => "Hello, <<name>>"}}},
                                       %{"b" => %{"type" => %{"a" => %{"name" => "John Galt"}}}}
                                      ],
                   "resources" => [%{"type" => "b",
                                     "relativeUri" => "/",
                                     "relativeUriPathSegments" => [],
                                     "methods" => [%{"method" => "get",
                                                     "description" => "Hello, John Galt"
                                                    }]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should allow injecting resource type name into another resource type" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      resourceTypes:
         - resourceType1:
             type: <<resourceTypeName>>
             get:
         - resourceType2:
             post:
      /:
         type:
             resourceType1:
                 resourceTypeName: resourceType2
         delete:
      """
      expected = %{"title" => "Title",
                   "resourceTypes" => [%{"resourceType1" => %{"type" => "<<resourceTypeName>>",
                                                              "get" => nil
                                                             }},
                                       %{"resourceType2" => %{"post" => nil}}
                                      ],
                   "resources" => [%{"relativeUriPathSegments" => [],
                                     "relativeUri" => "/",
                                     "type" => %{"resourceType1" => %{"resourceTypeName" => "resourceType2"}},
                                     "methods" => [%{"method" => "post"},
                                                   %{"method" => "get"},
                                                   %{"method" => "delete"}
                                                  ]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should not crash and report proper error if injected resource type does not exist" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      resourceTypes:
         - type1:
             type: <<typeName>>
      /:
         type:
             type1:
                 typeName: type2
      """
      assert_raise(RamlParseError, ~r(there is no resource type named type2), fn ->
        parse_string!(str)
      end)
    end

    it "should not allow reserved parameters" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      resourceTypes:
         - type1:
             description: <<resourcePath>>
      /:
         type:
             type1:
                 resourcePath: does-not-matter
      """
      assert_raise(RamlParseError, ~r(invalid parameter name: resourcePath is reserved), fn ->
        parse_string!(str)
      end)
    end

    it "should provide reserved <<resourcePathName>> parameter" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      resourceTypes:
         - type1:
             description: <<resourcePathName>>
      /a/b/c:
         type: type1
      """
      {:ok, result} = parse_string(str)
      %{"resources" => [%{"description" => description} | _]} = result
      assert description == "c"
    end

    it "should provide reserved <<resourcePathName>> parameter when there are variables in the URI" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      resourceTypes:
         - type1:
             description: <<resourcePathName>>
      /a/b/{c}:
         type: type1
      """
      {:ok, result} = parse_string(str)
      %{"resources" => [%{"description" => description} | _]} = result
      assert description == "b"
    end

    it "should provide reserved <<resourcePathName>> parameter when there are only variables in the URI" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      resourceTypes:
         - type1:
             description: <<resourcePathName>>
      /{a}/{b}/{c}:
         type: type1
      """
      {:ok, result} = parse_string(str)
      %{"resources" => [%{"description" => description} | _]} = result
      assert description == ""
    end

    it "should check for empty resource type name provided as a parameter to another resource type" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      resourceTypes:
        - resourceType1:
            type: <<resourceTypeName>>
      /:
        type:
          resourceType1:
            resourceTypeName:
      """
      assert_raise(RamlParseError, ~r(resource type name must be provided), fn ->
        parse_string!(str)
      end)
    end
  end
end
