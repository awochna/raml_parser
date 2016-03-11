defmodule RamlParser.OptionalsTest do
  @moduledoc """

  """

  use ExSpec, async: true
  import RamlParser

  describe "Optional scalar parameters" do
    @properties [
      {"displayName?", ": displayName"},
      {"description?", ": description"},
      {"is?", ": sometrait"},
      {"usage?", ": usage"},
      {"type?", ": type"},
      {"securedBy?", ": securedBy"}
    ]
    for {property, value} <- @properties do
      @tag property: property
      @tag value: value
      it "should reject scalar optional parameters in a resource type: #{property}", context do
        property = context[:property]
        value = context[:value]
        str = """
        #%RAML 0.8
        title: Title
        resourceTypes:
          - failType:
              #{property <> value}
        """
        assert_raise(RamlParseError, ~r(property: '#{property}' in invalid in a resource type), fn ->
          parse_string!(str)
        end)
      end
    end
    
    @properties [
      {"displayName?", ": displayName"},
      {"pattern?", ": pattern"},
      {"default?", ": default"},
      {"description?", ": description"},
      {"example?", ": example"},
      {"minLength?", ": 12"},
      {"maxLength?", ": 21"},
      {"minimum?", ": 1"},
      {"maximum?", ": 2"},
      {"type?", ": string"},
      {"required?", ": false"},
      {"repeat?", ": true"}
    ]
    for {property, value} <- @properties do
      @tag property: property
      @tag value: value
      it "should reject scalar optional parameters in a named parameter: #{property}", context do
        property = context[:property]
        value = context[:value]
        str = """
        #%RAML 0.8
        title: Title
        resourceTypes:
          - failType:
              uriParameters:
                failParam:
                  #{property <> value}
        """
        assert_raise(RamlParseError, ~r(unknown property: '#{property}), fn ->
          parse_string!(str)
        end)
      end
    end
    
    it "should reject scalar optional description in a response" do
      str = """
      #%RAML 0.8
      title: Title
      resourceTypes:
        - failType:
            get:
              responses:
                200:
                  description?: description
      """
      assert_raise(RamlParseError, ~r(property: 'description?' is invalid in a response), fn ->
        parse_string!(str)
      end)
    end

    it "should reject scalar optional example in a body" do
      str = """
      #%RAML 0.8
      title: Title
      resourceTypes:
        - failType:
            get:
              responses:
                200:
                  example?: example
      """
      assert_raise(RamlParseError, ~r(property: 'example' in invalid in a response), fn ->
        parse_string!(str)
      end)
    end

    it "should reject scalar optional schema in a body" do
      str = """
      #%RAML 0.8
      title: Title
      resourceTypes:
        - failType:
            get:
              responses:
                200:
                  schema?: schema
      """
      assert_raise(RamlParseError, ~r(property: 'schema?' is invalid in a response), fn ->
        parse_string!(str)
      end)
    end

    @properties [
      {"displayName?", ": displayName"},
      {"description?", ": description"},
      {"usage?", ": usage"},
      {"securedBy?", ": securedBy"}
    ]
    for {property, value} <- @properties do
      @tag property: property
      @tag value: value
      it "should reject scalar optional parameters in a trait: #{property}", context do
        property = context[:property]
        value = context[:value]
        str = """
        #%RAML 0.8
        title: Title
        traits:
          - failTrait:
              #{property <> value}
        """
        assert_raise(RamlParseError, ~r(property: '#{property}' is invalid in a trait), fn ->
          parse_string!(str)
        end)
      end
    end
  end
end
