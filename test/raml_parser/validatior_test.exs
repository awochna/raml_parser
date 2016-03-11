defmodule RamlParser.ValidatorTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/validator.js
  """

  use ExSpec, async: true
  import RamlParser

  describe "Validator" do
    it "should fail if baseUriParameters is defined without baseUri" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUriParameters:
      """
      assert_raise(RamlParseError, ~r(uri parameters defined when there is no baseUri), fn ->
        parse_string!(str)
      end)
    end

    it "should allow protocols at root level" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      protocols:
         - HTTP
         - HTTPS
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should fail if protocols property is not an array at root level" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      protocols: HTTP, HTTPS
      """
      assert_raise(RamlParseError, ~r(property must be an array), fn ->
        parse_string!(str)
      end)
    end

    it "should fail if protocols property contains not-a-string values at root level" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      protocols:
         - {}
      """
      assert_raise(RamlParseError, ~r(value must be a string), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 6
        assert error.column == 6
        raise error
      end)
    end

    it "should fail if protocols property contains invalid values at root level" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      protocols:
         - HTTP
         - FTP
      """
      assert_raise(RamlParseError, ~r(only HTTP and HTTPS values are allowed), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 7
        assert error.column == 6
        raise error
      end)
    end

    it "should not allow valid protocols in mixed cases at root level" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      protocols:
         - HtTp
         - hTtPs
      """
      assert_raise(RamlParseError, ~r(only HTTP and HTTPS values are allowed), fn ->
        parse_string!(str)
      end)
    end

    it "should allow protocols at method level" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      /:
         get:
             protocols:
                 - HTTP
                 - HTTPS
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should fail if protocols property is not an array at method level" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      /:
         get:
             protocols: HTTP, HTTPS
      """
      assert_raise(RamlParseError, ~r(property must be an array), fn ->
        parse_string!(str)
      end)
    end

    it "should fail if protocols property contains not-a-string values at method level" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      /:
         get:
             protocols:
                 - {}
      """
      assert_raise(RamlParseError, ~r(value must be a string), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 8
        assert error.column == 14
        raise error
      end)
    end

    it "should fail if protocols property contains invalid values at method level" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      /:
         get:
             protocols:
                 - HTTP
                 - FTP
      """
      assert_raise(RamlParseError, ~r(only HTTP and HTTPS values are allowed), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 9
        assert error.column == 14
        raise error
      end)
    end

    it "should not allow valid protocols in mixed cases at method level" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      /:
         get:
             protocols:
                 - HtTp
      """
      assert_raise(RamlParseError, ~r(only HTTP and HTTPS values are allowed), fn ->
        parse_string!(str)
      end)
    end

    it "should allow protocols in traits" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      traits:
         - trait1:
             protocols:
                 - HTTP
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should not allow protocols in resources" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      /:
         protocols:
             - HTTP
      """
      assert_raise(RamlParseError, ~r(property: 'protocols' is invalid in a resource), fn ->
        parse_string!(str)
      end)
    end

    it "should not allow parameter key to be used as a name for resource type" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      resourceTypes:
         - <<resourceTypeName>>: {}
      """
      assert_raise(RamlParseError, ~r(parameter key cannot be used as a resource type name), fn ->
        parse_string!(str)
      end)
    end

    it "should not allow parameter key to be used as a name for trait" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      traits:
         - <<traitName>>: {}
      """
      assert_raise(RamlParseError, ~r(parameter key cannot be used as a trait name), fn ->
        parse_string!(str)
      end)
    end

    it "should allow use parameter key as a trait name within resource type" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      resourceTypes:
         - resourceType1:
             is:
                 - <<traitName>>
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should allow use parameter key as a resource type name within resource type" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      resourceTypes:
         - resourceType1:
             type: <<resourceTypeName>>
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should not allow baseUri to be empty" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri:
      """
      assert_raise(RamlParseError, ~r(baseUri must have a value), fn ->
        parse_string!(str)
      end)
    end

    it "should allow only HTTP and HTTPS protocols to be used in baseUri" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: ftp://api.com
      """
      assert_raise(RamlParseError, ~r(baseUri protocol must be either HTTP or HTTPS), fn ->
        parse_string!(str)
      end)
    end

    it "should report correct line/column for scheme entry that is not a map" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      securitySchemes:
         - scheme1:
      """
      assert_raise(RamlParseError, ~r(invalid security scheme property, it must be a map), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 5
        assert error.column == 6
        raise error
      end)
    end

    it "should report correct line/column when accessTokenUri has not been specified for OAuth 2.0 security scheme" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      securitySchemes:
         - scheme1:
             type: OAuth 2.0
             settings: {}
      """
      assert_raise(RamlParseError, ~r(OAuth 2.0 settings must have accessTokenUri property), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 7
        assert error.column == 8
        raise error
      end)
    end

    it "should report correct line/column when authorizationUri has not been specified for OAuth 2.0 security scheme" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      securitySchemes:
         - scheme1:
             type: OAuth 2.0
             settings:
                 accessTokenUri: i-dont-care
      """
      assert_raise(RamlParseError, ~r(OAuth 2.0 settings must have authorizationUri property), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 7
        assert error.column == 8
        raise error
      end)
    end

    it "should report correct line/column when authorizationUri has not been specified for OAuth 1.0 security scheme" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      securitySchemes:
         - scheme1:
             type: OAuth 1.0
             settings:
                 requestTokenUri: i-dont-care
      """
      assert_raise(RamlParseError, ~r(OAuth 1.0 settings must have authorizationUri property), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 7
        assert error.column == 8
        raise error
      end)
    end

    it "should report correct line/column when tokenCredentialsUri has not been specified for OAuth 1.0 security scheme" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      securitySchemes:
         - scheme1:
             type: OAuth 1.0
             settings:
                 requestTokenUri: i-dont-care
                 authorizationUri: i-dont-care
      """
      assert_raise(RamlParseError, ~r(OAuth 1.0 settings must have tokenCredentialsUri property), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 7
        assert error.column == 8
        raise error
      end)
    end

    it "should allow typed parameters in a resource type in a named parameter that should be a non-string" do
      str = """
      #%RAML 0.8
      title: Title
      resourceTypes:
        - type1:
            uriParameters:
              param1:
                type: number
                maximum: <<parameterName>>
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should allow untyped parameters in a resource type in a named parameter that should be a non-string" do
      str = """
      #%RAML 0.8
      title: Title
      resourceTypes:
        - type1:
            uriParameters:
              param1:
                required: <<parameterName>>
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should allow typed parameters in a trait in a named parameter that should be a non-string" do
      str = """
      #%RAML 0.8
      title: Title
      traits:
        - trait:
            headers:
              param1:
                type: number
                maximum: <<parameterName>>
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should allow untyped parameters in a trait in a named parameter that should be a non-string" do
      str = """
      #%RAML 0.8
      title: Title
      traits:
        - trait:
            headers:
              param1:
                required: <<parameterName>>
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should allow applied trait to be a null (implicit empty map)" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      traits:
         - trait1: {}
      /:
         get:
             is:
               - trait1:
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should report that applied trait value must be a map" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      traits:
         - trait1: {}
      /:
         get:
             is:
               - trait1:
                 - 1
      """
      assert_raise(RamlParseError, ~r(trait must be a map), fn ->
        parse_string!(str)
      end)
    end

    it "should allow only scalar values to be used for parameters when applying traits #1" do
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
                   param1: []
      """
      assert_raise(RamlParseError, ~r(parameter value must be a scalar), fn ->
        parse_string!(str)
      end)
    end

    it "should allow only scalar values to be used for parameters when applying traits #2" do
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
                   param1: {}
      """
      assert_raise(RamlParseError, ~r(parameter value must be a scalar), fn ->
        parse_string!(str)
      end)
    end

    it "should allow only scalar values to be used for parameters when applying resource types #1" do
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
                   param1: []
      """
      assert_raise(RamlParseError, ~r(parameter value must be a scalar), fn ->
        parse_string!(str)
      end)
    end

    it "should allow only scalar values to be used for parameters when applying resouce types #2" do
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
                   param1: {}
      """
      assert_raise(RamlParseError, ~r(parameter value must be a scalar), fn ->
        parse_string!(str)
      end)
    end

    it "should check for empty trait name within resource method" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      /:
         get:
             is:
               -
      """
      assert_raise(RamlParseError, ~r(trait name must be provided), fn ->
        parse_string!(str)
      end)
    end

    it "should check for empty trait name within resource type method" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      resourceTypes:
        - resourceType1:
            get:
              is:
                -
      """
      assert_raise(RamlParseError, ~r(trait name must be provided), fn ->
        parse_string!(str)
      end)
    end

    it "should check for empty trait name filled with whitespaces only within resource method" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      /:
         get:
             is:
               -  
      """
      assert_raise(RamlParseError, ~r(trait name must be provided), fn ->
        parse_string!(str)
      end)
    end

    it "should check for empty trait name filled with whitespaces only within resource type method" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      resourceTypes:
        - resourceType1:
            get:
              is:
                -  
      """
      assert_raise(RamlParseError, ~r(trait name must be provided), fn ->
        parse_string!(str)
      end)
    end

    it "should check for empty resource type name" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      /:
        type: " "
      """
      assert_raise(RamlParseError, ~r(resource type name must be provided), fn ->
        parse_string!(str)
      end)
    end

    describe "JSON Schema" do

      it "should report an error in the middle of the string" do
        str = """
        #%RAML 0.8
        ---
        title: Title
        schemas:
          - schema: |
              {
                ": ""
              }
        """
        assert_raise(RamlParseError, ~r(schema is not valid JSON, error: 'Unexpected token' at 2:7), fn ->
          {:error, error} = parse_string(str)
          assert error.line == 7
          assert error.column == 1
          raise error
        end)
      end

      it "should not detect a JSON schema if character is not a {" do
        str = """
        #%RAML 0.8
        ---
        title: Title
        schemas:
          - schema: |
              a{
                "": ""
              }
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it "should report an error at the end of the schema if there is a missing }" do
        str = """
        #%RAML 0.8
        ---
        title: Title
        schemas:
          - schema: |
              {
                "": ""
        baseUri: http://pepe.com
        """
        assert_raise(RamlParseError, ~r(schema is not valid JSON, error: 'Unexpected e.d of input' at 3:2), fn ->
          {:error, error} = parse_string(str)
          assert error.line == 7
          assert error.column == 1
          raise error
        end)
      end
    end

    @methods [
      # RFC2616
      "options",
      "get",
      "head",
      "post",
      "put",
      "delete",
      "trace",
      "connect",
      # RFC5789
      "patch"
    ]
    for method <- @methods do
      @tag method: method
      it "should allow '#{method}' HTTP method", context do
        method = context[:method]
        str = """
        #%RAML 0.8
        ---
        title: Title
        /:
          #{method}:
        """
        {:ok, result} = parse_string(str)
        result_method =
          result
        |> Map.get("resources")
        |> Enum.at(0)
        |> Map.get("methods")
        |> Enum.at(0)
        |> Map.get("method")

        assert result_method == method
      end
    end

    @types [
      "number",
      "integer",
      "date",
      "boolean",
      "file"
    ]
    for type <- @types do
      @properties [
        {"enum", ~s(: ["value1"])},
        {"pattern", ": somevalue"},
        {"minLength", ": 1"},
        {"maxLength", ": 3"}
      ]
      for {property, value} <- @properties do
        @tag type: type
        @tag property: property
        @tag value: value
        it "should reject because string property is unusable in #{property} for the type #{type}", context do
          type = context[:type]
          property = context[:property]
          value = context[:value]
          str = """
          #%RAML 0.8
          title: Title
          /{param}:
            uriParameters:
              param:
                type: #{type}
                #{property <> value}
          """
          assert_raise(RamlParseError, ~r(property: '#{property}' can only be used if type is 'string'), fn ->
            parse_string!(str)
          end)
        end
      end
    end

    @types [
      "string",
      "date",
      "boolean",
      "file"
    ]
    for type <- @types do
      @properties [
        {"minimum", ": 1"},
        {"maximim", ": 3"}
      ]
      for {property, value} <- @properties do
        @tag type: type
        @tag property: property
        @tag value: value
        it "should reject because number/integer property is unusable in #{property} for the type #{type}", context do
          type = context[:type]
          property = context[:property]
          value = context[:value]
          str = """
          #%RAML 0.8
          title: Title
          /{param}:
            uriParameters:
              param:
                type: #{type}
                #{property <> value}
          """
          assert_raise(RamlParseError, ~r(property: '#{property}' can only be used if type is 'number' or 'integer'), fn ->
            parse_string!(str)
          end)
        end
      end
    end

    @properties [
      {"enum", ~s(: ["value1"])},
      {"pattern", ": somevalue"},
      {"minLength", "1"},
      {"maxLength", "3"}
    ]
    for {property, value} <- @properties do
      @tag property: property
      @tag value: value
      it "should succeed because default type in #{property} is string", context do
        property = context[:property]
        value = context[:value]
        str = """
        #%RAML 0.8
        title: Title
        /{param}:
          uriParameters:
            param:
              #{property <> value}
        """
        {:ok, result} = parse_string(str)
        assert result
      end
    end
  end
end
