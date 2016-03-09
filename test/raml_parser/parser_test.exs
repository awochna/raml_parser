defmodule RamlParser.ParserTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/parser.js
  """

  use ExSpec
  import RamlParser

  describe "Parser" do
    it "should be tolerant to whitespaces around version" do
      str = """
      ' #%RAML 0.8 ',
      '---',
      'title: MyApi'
      """
      {:ok, response} = parse_string(str)
      assert response
    end

    describe "Basic Information" do
      it "should fail unsupported yaml version" do
        str = """
        '#%RAML 0.8',
        '%YAML 1.1',
        '---',
        'title: MyApi'
        """
        assert_raise(RamlParseError, ~r/found incompatible YAML document \(version 1.2 is required\)/, fn ->
          parse_string!(str)
        end)
      end

      it "should succeed" do
        str = """
        '#%RAML 0.8',
        '%YAML 1.2',
        '---',
        'title: MyApi',
        'baseUri: http://myapi.com',
        '/:',
        '  displayName: Root'
        """
        expected = %{"title" => "MyApi",
                     "baseUri" => "http://myapi.com",
                     "resources" => [%{"relativeUriPathSegments" => [],
                                       "relativeUri" => "/",
                                       "displayName" => "Root"
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if no title" do
        str = """
        '#%RAML 0.8',
        '---',
        'baseUri: http://myapi.com'
        """
        assert_raise(RamlParseError, ~r(missing title), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if title is array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: ["title", "title line 2", "title line 3"]',
        'baseUri: http://myapi.com'
        """
        assert_raise(RamlParseError, ~r(title must be a string), fn ->
          parse_string!(str)
        end)
      end

      describe "feature flags" do
        it "should not validate title if flag is set not to validate" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: ["title", "title line 2", "title line 3"]',
          'baseUri: http://myapi.com'
          """
          {:ok, result} = parse_string(str, validate: false, transform: false, compose: true)
          assert result
        end

        it "should not validate title if flag is set not to validate" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: ["title", "title line 2", "title line 3"]',
          'baseUri: http://myapi.com'
          """
          {:ok, result} = parse_string(str, validate: false, transform: true, compose: true)
          assert result
        end

        it "should not apply transformations if flag is set to ignore" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: some title',
          'baseUri: http://myapi.com/'
          """
          expected = %{"title" => "some title",
                       "baseUri" => "http://myapi.com/"
                      }
          {:ok, result} = parse_string(str, validate: false, transform: false, compose: true)
          assert result == expected
        end

        it "should not apply transformations if flag is set to ignore" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: some title',
          'baseUri: http://myapi.com/'
          """
          expected = %{"title" => "some title",
                       "baseUri" => "http://myapi.com/"
                      }
          {:ok, result} = parse_string(str, validate: true, transform: false, compose: true)
          assert result == expected
        end

        it "should apply transformations if flag is set to ignore" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: some title',
          'baseUri: http://myapi.com/'
          """
          expected = %{"title" => "some title",
                       "baseUri" => "http://myapi.com/",
                       "protocols" => ["HTTP"]
                      }
          {:ok, result} = parse_string(str, validate: true, transform: true, compose: true)
          assert result == expected
        end

        it "should apply transformations if compose not set" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: some title',
          'baseUri: http://myapi.com/'
          """
          expected = %{"title" => "some title",
                       "baseUri" => "http://myapi.com/",
                       "protocols" => ["HTTP"]
                      }
          {:ok, result} = parse_string(str, validate: true, transform: true)
          assert result == expected
        end
      end

      it "should fail if title is map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: { line 1: line 1, line 2: line 2 }',
        'baseUri: http://myapi.com'
        """
        assert_raise(RamlParseError, ~r(title must be a string), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed if title is longer than 48 chars" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: this is a very long title, it should fail the length validation for titles with an exception clearly marking it so',
        'baseUri: http://myapi.com'
        """
        expected = %{"title" => "this is a very long title, it should fail the length validation for titles with an exception clearly marking it so",
                     "baseUri" => "http://myapi.com",
                     "protocols" => ["HTTP"]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should allow number title" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: 54',
        'baseUri: http://myapi.com'
        """
        expected = %{"title" => 54,
                     "baseUri" => "http://myapi.com",
                     "protocols" => ["HTTP"]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if there is a root property with wrong displayName" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'version: v1',
        'wrongPropertyName: http://myapi.com/{version}'
        """
        assert_raise(RamlParseError, ~r(unknown property), fn ->
          parse_string!(str)
        end)
      end

      it "should coherce version to be a string even when it is a float" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'version: 1.0'
        """
        expected = %{"title" => "MyApi",
                     "version" => "1.0"
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should coherce version to be a string even when it is an int" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'version: 1'
        """
        expected = %{"title" => "MyApi",
                     "version" => "1"
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if there is a root property with array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'version: v1',
        '[1,2]: v1'
        """
        assert_raise(RamlParseError, ~r(only scalar map keys are allowed in RAML), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "Include" do
      it "should fail if include not found" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: !include relative.md'
        """
        assert_raise(RamlParseError, ~r/cannot (read|fetch) relative\.md/, fn ->
          parse_string!(str)
        end)
      end

      it 'should succeed on including another YAML file with .yml extension' do
        str = """
        '#%RAML 0.8',
        '---',
        '!include test/assets/external.yml'
        """
        expected = %{"title" => "MyApi",
                     "documentation" => [%{"title" => "Getting Started",
                                           "content" => "# Getting Started\n\nThis is a getting started guide."
                                          }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it 'should succeed on including another YAML file with .yaml extension' do
        str = """
        '#%RAML 0.8',
        '---',
        '!include test/assests/external.yaml'
        """
        expected = %{"title" => "MyApi",
                     "documentation" => [%{"title" => "Getting Started",
                                           "content" => "# Getting Started\n\nThis is a getting started guide."
                                          }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it 'should succeed on including another YAML file mid-document' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '   - customTrait1: !include test/assets/customtrait.yml',
        '   - customTrait2: !include test/assets/customtrait.yml'
        """
        expected = %{"title" => "Test",
                     "traits" => [%{"customTrait1" => %{"displayName" => "Custom Trait",
                                                        "description" => "This is a custom trait",
                                                        "responses" => %{"429" => %{"description" => "API Limit Exceeded"}}}
                                   },
                                  %{"customTrait2" => %{"displayName" => "Custom Trait",
                                                        "description" => "This is a custom trait",
                                                        "responses" => %{"429" => %{"description" => "API Limit Exceeded"}}}
                                   }
                                 ]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end
    end

    describe "URI Parameters" do
      it "should succeed when dealing with URI parameters" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        ''
        """
        expected = %{"title" => "Test",
                     "baseUri" => "http://{a}.myapi.org",
                     "baseUriParameters" => %{"a" => %{"displayName" => "A",
                                                       "description" => "This is A",
                                                       "required" => true,
                                                       "type" => "string"
                                                      }},
                     "protocols" => ["HTTP"]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail when a parameter uses array syntax with only one type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    - displayName: A',
        '      description: This is A',
        ''
        """
        assert_raise(RamlParseError, ~r(single type for variably typed parameter), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed when dealing with URI parameters with two types" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    - displayName: A',
        '      description: This is A',
        '      type: string',
        '    - displayName: A',
        '      description: This is A',
        '      type: file',
        """
        expected = %{"title" => "Test",
                     "baseUri" => "http://{a}.myapi.org",
                     "baseUriParameters" => %{"a" => [%{"displayName" => "A",
                                                        "description" => "This is A",
                                                        "type" => "string",
                                                        "required" => true
                                                       },
                                                      %{"displayName" => "A",
                                                        "description" => "This is A",
                                                        "type" => "file",
                                                        "required" => true
                                                       }
                                                     ]
                                             },
                     "protocols" => ["HTTP"]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail when declaring a URI parameter not on the baseUri" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  b:',
        '    displayName: A',
        '    description: This is A',
        ''
        """
        assert_raise(RamlParseError, ~r(uri parameter unused), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when declaring a URI parameter not on the resource URI" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '/{hello}:',
        '  uriParameters:',
        '    a:',
        '      displayName: A',
        '      description: This is A'
        """
        assert_raise(RamlParseError, ~r(uri parameter unused), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when declaring a property inside a URI parameter that is not valid" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    wrongPropertyName: X'
        """
        assert_raise(RamlParseError, ~r(unknown property wrongPropertyName), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed when declaring a minLength validation as a number" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    minLength: 123'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it "should fail when declaring an enum with duplicated values" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    minLength: 123',
        '    enum: [ "value", "value2", "value2" ]'
        """
        assert_raise(RamlParseError, ~r(enum contains duplicated values), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when declaring an enum with no values" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    minLength: 123',
        '    enum: []'
        """
        assert_raise(RamlParseError, ~r(enum is empty), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when declaring an enum with null value" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    minLength: 123',
        '    enum:'
        """
        assert_raise(RamlParseError, ~r(enum is empty), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when declaring an enum with map value" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    minLength: 123',
        '    enum: {}'
        """
        assert_raise(RamlParseError, ~r(the value of enum must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed when declaring a maxLength validation as a number" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    maxLength: 123'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it "should succeed when declaring a minimum validation as a number" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    type: number',
        '    displayName: A',
        '    description: This is A',
        '    minimum: 123'
        """
        {:ok, result} = parse_string(str)
        assert result
      end
      it "should succeed when declaring a maximum validation as a number" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    type: number',
        '    displayName: A',
        '    description: This is A',
        '    maximum: 123'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it "should fail when declaring a minLength validation as anything other than a number" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    minLength: X'
        """
        assert_raise(RamlParseError, ~r(the value of minLength must be a number), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when declaring a maxLength validation as anything other than a number" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    maxLength: X'
        """
        assert_raise(RamlParseError, ~r(the value of maxLength must be a number), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when declaring a minimum validation as anything other than a number" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    minimum: X'
        """
        assert_raise(RamlParseError, ~r(the value of minimum must be a number), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when declaring a maximum validation as anything other than a number" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    maximum: X'
        """
        assert_raise(RamlParseError, ~r(the value of maximum must be a number), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when declaring a URI parameter with an invalid type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: X'
        """
        assert_raise(RamlParseError, ~r(type can be either of: string, number, integer, file, date or boolean), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed when declaring a URI parameter with a string type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: string'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it "should succeed when declaring a URI parameter with a number type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: number'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it "should succeed when declaring a URI parameter with a integer type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: integer'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it "should succeed when declaring a URI parameter with a date type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it "should succeed when declaring a URI parameter with a file type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: file'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it "should succeed when declaring a URI parameter with a boolean type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: boolean'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it "should succeed when declaring a URI parameter with an example" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    example: This is the example'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it "should fail if baseUri value its not really a URI" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'baseUri: http://{myapi.com'
        """
        assert_raise(RamlParseError, ~r(unclosed brace), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if baseUri uses version but there is no version defined" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'baseUri: http://myapi.com/{version}'
        """
        assert_raise(RamlParseError, ~r(missing version), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed if baseUri uses version and there is a version defined" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'version: v1',
        'baseUri: http://myapi.com/{version}'
        """

        expected = %{"title" => 'MyApi',
                     "version" => 'v1',
                     "baseUri" => 'http://myapi.com/{version}',
                     "baseUriParameters" => %{"version" => %{"type" => "string",
                                                             "required" => true,
                                                             "displayName" => "version",
                                                             "enum" => ["v1"]
                                                            }},
                     "protocols" => ['HTTP']
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it 'should fail when a URI parameter has required "y"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    required: y'
        """
        assert_raise(RamlParseError, fn ->
          parse_string!(str)
        end)
      end

      it 'should fail when a URI parameter has required "yes"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    required: yes'
        """
        assert_raise(RamlParseError, fn ->
          parse_string!(str)
        end)
      end

      it 'should fail when a URI parameter has required "YES"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    required: YES'
        """
        assert_raise(RamlParseError, fn ->
          parse_string!(str)
        end)
      end

      it 'should fail when a URI parameter has required "t"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    required: t'
        """
        assert_raise(RamlParseError, fn ->
          parse_string!(str)
        end)
      end

      it 'should succeed when a URI parameter has required "true"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    required: true'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it 'should fail when a URI parameter has required "TRUE"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    required: TRUE'
        """
        assert_raise(RamlParseError, fn ->
          parse_string!(str)
        end)
      end

      it 'should fail when a URI parameter has required "n"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    required: n'
        """
        assert_raise(RamlParseError, fn ->
          parse_string!(str)
        end)
      end

      it 'should fail when a URI parameter has required "no"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    required: no'
        """
        assert_raise(RamlParseError, fn ->
          parse_string!(str)
        end)
      end

      it 'should fail when a URI parameter has required "NO"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    required: NO'
        """
        assert_raise(RamlParseError, fn ->
          parse_string!(str)
        end)
      end

      it 'should fail when a URI parameter has required "f"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    required: f'
        """
        assert_raise(RamlParseError, fn ->
          parse_string!(str)
        end)
      end

      it 'should succeed when a URI parameter has required "false"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    required: false'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it 'should fail when a URI parameter has required "FALSE"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    required: FALSE'
        """
        assert_raise(RamlParseError, fn ->
          parse_string!(str)
        end)
      end

      it 'should succeed when a URI parameter has repeat "false"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    repeat: false'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it 'should fail when a URI parameter has repeat "FALSE"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    repeat: FALSE'
        """
        assert_raise(RamlParseError, fn ->
          parse_string!(str)
        end)
      end

      it 'should succeed when a URI parameter has repeat "true"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    repeat: true'
        """
        {:ok, result} = parse_string(str)
        assert result
      end

      it 'should fail when a URI parameter has repeat "TRUE"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '    type: date',
        '    repeat: TRUE'
        """
        assert_raise(RamlParseError, fn ->
          parse_string!(str)
        end)
      end
    end

    describe "MultiType Named Parameters" do
      describe "Named parameters in baseUriParameters at root level" do
        it "should succeed with null baseUriParameters" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          'baseUriParameters:',
          """
          expected = %{"title" => "Test",
                       "baseUri" => "http://myapi.org",
                       "baseUriParameters" => nil,
                       "protocols" => ['HTTP']
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should fail when a parameter uses array syntax with no types" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://{a}.myapi.org',
          'baseUriParameters:',
          '  a: []'
          """
          assert_raise(RamlParseError, ~r(named parameter needs at least one type), fn ->
            parse_string!(str)
          end)
        end

        it "should fail when a parameter uses array syntax with only one type" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://{a}.myapi.org',
          'baseUriParameters:',
          '  a:',
          '    - displayName: A',
          '      description: This is A',
          ''
          """
          assert_raise(RamlParseError, ~r(single type for variably typed parameter), fn ->
            parse_string!(str)
          end)
        end

        it "should succeed when dealing with URI parameters with two types" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://{a}.myapi.org',
          'baseUriParameters:',
          '  a:',
          '    - displayName: A',
          '      description: This is A',
          '      type: string',
          '    - displayName: A',
          '      description: This is A',
          '      type: file',
          """
          expected = %{"title" => 'Test',
                       "baseUri" => 'http://{a}.myapi.org',
                       "baseUriParameters" => %{"a" => [%{"displayName" => 'A',
                                                          "description" => 'This is A',
                                                          "type" => "string",
                                                          "required" => true
                                                         },
                                                        %{"displayName" => 'A',
                                                          "description" => 'This is A',
                                                          "type" => "file",
                                                          "required" => true
                                                         },
                                                       ]},
                       "protocols" => ['HTTP']
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end
      end

      describe "Named parameters in baseUriParameters at a resource level" do
        it "should succeed with null baseUriParameters" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://{a}.myapi.org',
          '/resource:',
          '  baseUriParameters:',
          """
          expected = %{"title" => 'Test',
                       "baseUri" => 'http://{a}.myapi.org',
                       "baseUriParameters" => %{"a" => %{"displayName" => 'a',
                                                         "type" => "string",
                                                         "required" => true
                                                        }},
                       "protocols" => ['HTTP'],
                       "resources" => [%{"relativeUriPathSegments" => ["resource"],
                                         "relativeUri" => "/resource",
                                         "baseUriParameters" => nil
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should fail when a parameter uses array syntax with no types" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://{a}.myapi.org',
          '/resource:',
          '  baseUriParameters:',
          '    a: []'
          """
          assert_raise(RamlParseError, ~r(named parameter needs at least one type), fn ->
            parse_string!(str)
          end)
        end

        it "should fail when a parameter uses array syntax with only one type" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://{a}.myapi.org',
          '/resource:',
          '  baseUriParameters:',
          '    a:',
          '      - displayName: A',
          '        description: This is A',
          ''
          """
          assert_raise(RamlParseError, ~r(single type for variably typed parameter), fn ->
            parse_string!(str)
          end)
        end

        it "should succeed when dealing with URI parameters with two types" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://{a}.myapi.org',
          '/resource:',
          '  baseUriParameters:',
          '    a:',
          '      - displayName: A',
          '        description: This is A',
          '        type: string',
          '      - displayName: A',
          '        description: This is A',
          '        type: file',
          """
          expected = %{"title" => 'Test',
                       "baseUri" => 'http://{a}.myapi.org',
                       "resources" => [%{"baseUriParameters" => %{"a" => [%{"displayName" => 'A',
                                                                            "description" => 'This is A',
                                                                            "type" => "string",
                                                                            "required" => true
                                                                           },
                                                                          %{"displayName" => 'A',
                                                                            "description" => 'This is A',
                                                                            "type" => "file",
                                                                            "required" => true
                                                                           }
                                                                         ]},
                                         "relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"]
                                        }],
                       "baseUriParameters" => %{"a" => %{"type" => "string",
                                                         "required" => true,
                                                         "displayName" => 'a'
                                                        }},
                       "protocols" => ['HTTP']
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end
      end

      describe "Named parameters in uriParameters" do
        it "should succeed with null uriParameters" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/{a}resource:',
          '  uriParameters:'
          """

          expected = %{"title" => 'Test',
                       "baseUri" => 'http://myapi.org',
                       "protocols" => ['HTTP'],
                       "resources" => [%{"relativeUri" => "/{a}resource",
                                         "relativeUriPathSegments" => ["{a}resource"],
                                         "uriParameters" => %{"a" => %{"displayName" => 'a',
                                                                       "required" => true,
                                                                       "type" => "string"
                                                                      }}
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should fail when a parameter uses array syntax with no types" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/{a}resource:',
          '  uriParameters:',
          '    a: []'
          """

          assert_raise(RamlParseError, ~r(named parameter needs at least one type), fn ->
            parse_string!(str)
          end)
        end

        it "should fail when a parameter uses array syntax with only one type" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/{a}resource:',
          '  uriParameters:',
          '    a:',
          '      - displayName: A',
          '        description: This is A',
          ''
          """

          assert_raise(RamlParseError, ~r(single type for variably typed parameter), fn ->
            parse_string!(str)
          end)
        end

        it "should succeed when dealing with URI parameters with two types" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/{a}resource:',
          '  uriParameters:',
          '    a:',
          '      - displayName: A',
          '        description: This is A',
          '        type: string',
          '      - displayName: A',
          '        description: This is A',
          '        type: file',
          """

          expected = %{"title" => 'Test',
                       "baseUri" => 'http://myapi.org',
                       "protocols" => ['HTTP'],
                       "resources" => [%{"relativeUri" => "/{a}resource",
                                         "relativeUriPathSegments" => ["{a}resource"],
                                         "uriParameters" => %{"a" => [%{"displayName" => 'A',
                                                                        "description" => 'This is A',
                                                                        "type" => "string",
                                                                        "required" => true
                                                                       },
                                                                      %{"displayName" => 'A',
                                                                        "description" => 'This is A',
                                                                        "type" => "file",
                                                                        "required" => true
                                                                       },
                                                                     ]}
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end
      end

      describe "Named parameters in request headers" do
        it "should succeed with null headers" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    headers:'
          """

          expected = %{"title" => 'Test',
                       "baseUri" => 'http://myapi.org',
                       "protocols" => ['HTTP'],
                       "resources" => [%{"relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"method" => "get",
                                                         "protocols" => ['HTTP'],
                                                         "headers" => nil
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should fail when a parameter uses array syntax with only one type" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    headers:',
          '      a: []'
          """

          assert_raise(RamlParseError, ~r(named parameter needs at least one type), fn ->
            parse_string!(str)
          end)
        end

        it "should fail when a parameter uses array syntax with only one type" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    headers:',
          '      a:',
          '        - displayName: A',
          '          description: This is A',
          ''
          """

          assert_raise(RamlParseError, ~r(single type for variably typed parameter), fn ->
            parse_string!(str)
          end)
        end

        it "should succeed when dealing with URI parameters with two types" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    headers:',
          '      a:',
          '        - displayName: A',
          '          description: This is A',
          '          type: string',
          '        - displayName: A',
          '          description: This is A',
          '          type: file',
          """

          expected = %{"title" => 'Test',
                       "baseUri" => 'http://myapi.org',
                       "protocols" => ['HTTP'],
                       "resources" => [%{"relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"method" => "get",
                                                         "protocols" => ['HTTP'],
                                                         "headers" => %{"a" => [%{"displayName" => 'A',
                                                                                  "description" => 'This is A',
                                                                                  "type" => "string"
                                                                                 },
                                                                                %{"displayName" => 'A',
                                                                                  "description" => 'This is A',
                                                                                  "type" => "file"
                                                                                 }
                                                                               ]}
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should be required when explicitly marked" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: My API',
          '/:',
          '  get:',
          '    headers:',
          '      header1:',
          '        required: true'
          """
          {:ok, result} = parse_string(str)
          required =
            result
            |> Map.get("resources")
            |> Enum.at(0)
            |> Map.get("methods")
            |> Enum.at(0)
            |> Map.get("headers")
            |> Map.get("header1")
            |> Map.get("required")

          assert required == true
        end
      end

      describe "Named parameters in query string parameter" do
        it "should succeed with null URI parameters" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    queryParameters:'
          """

          expected = %{"title" => 'Test',
                       "baseUri" => 'http://myapi.org',
                       "protocols" => ['HTTP'],
                       "resources" => [%{"relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"method" => "get",
                                                         "protocols" => ['HTTP'],
                                                         "queryParameters" => nil
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "defaults query parameters requiredness to falsy" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    queryParameters:',
          '      notRequired:',
          '        type: integer'
          """

          expected = %{"title" => 'Test',
                       "baseUri" => 'http://myapi.org',
                       "protocols" => ['HTTP'],
                       "resources" => [%{"relativeUriPathSegments" => ["resource"],
                                         "relativeUri" => "/resource",
                                         "methods" => [%{"method" => "get",
                                                         "protocols" => ['HTTP'],
                                                         "queryParameters" => %{"notRequired" => %{"displayName" => 'notRequired',
                                                                                                   "type" => 'integer'
                                                                                                  }}
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should fail when a parameter uses array syntax with only one type" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    queryParameters:',
          '      a: []'
          """

          assert_raise(RamlParseError, ~r(named parameter needs at least one type), fn ->
            parse_string!(str)
          end)
        end

        it "should fail when a parameter uses array syntax with only one type" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    queryParameters:',
          '      a:',
          '        - displayName: A',
          '          description: This is A',
          ''
          """

          assert_raise(RamlParseError, ~r(single type for variably typed parameter), fn ->
            parse_string!(str)
          end)
        end

        it "should succeed when dealing with URI parameters with two types" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    queryParameters:',
          '      a:',
          '        - displayName: A',
          '          description: This is A',
          '          type: string',
          '        - displayName: A',
          '          description: This is A',
          '          type: file',
          """

          expected = %{"title" => 'Test',
                       "baseUri" => 'http://myapi.org',
                       "protocols" => ['HTTP'],
                       "resources" => [%{"relativeUriPathSegments" => ["resource"],
                                         "relativeUri" => "/resource",
                                         "methods" => [%{"method" => "get",
                                                         "protocols" => ['HTTP'],
                                                         "queryParameters" => %{"a" => [%{"displayName" => 'A',
                                                                                          "description" => 'This is A',
                                                                                          "type" => "string"
                                                                                         },
                                                                                        %{
                                                                                          "displayName" => 'A',
                                                                                          "description" => 'This is A',
                                                                                          "type" => "file"
                                                                                        }
                                                                                       ]}
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should be required when explicitly marked" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: My API',
          '/:',
          '  get:',
          '    queryParameters:',
          '      queryParameter1:',
          '        required: true'
          """
          {:ok, result} = parse_string(str)
          required =
            result
          |> Map.get("resources")
          |> Enum.at(0)
          |> Map.get("methods")
          |> Enum.at(0)
          |> Map.get("queryParameters")
          |> Map.get("queryParameter1")
          |> Map.get("required")
          assert required == true
        end
      end

      describe "Named parameters in form parameters" do
        it "should fail if formParameters is used in a response" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  post:',
          '    responses: ',
          '      200:',
          '        body:',
          '          application/json:',
          '            formParameters:',
          """
          assert_raise(RamlParseError, ~r(formParameters cannot be used to describe response bodies), fn ->
            parse_string!(str)
          end)
        end

        it "should fail if formParameters is used together with schema" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  post:',
          '    body:',
          '      application/json:',
          '        formParameters:',
          '        schema:',
          """
          assert_raise(RamlParseError, ~r(formParameters cannot be used together with the example or schema properties'), fn ->
            {:error, error} = parse_string(str)
            assert error.line == 9
            assert error.column == 9
            raise error
            end)
        end

        it "should fail if formParameters is used together with example" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  post:',
          '    body:',
          '      application/json:',
          '        formParameters:',
          '        example:',
          """
          assert_raise(RamlParseError, ~r(formParameters cannot be used together with the example or schema properties), fn ->
            {:error, error} = parse_string(str)
            assert error.line == 9
            assert error.column == 9
            raise error
          end)
        end

        it "should succeed null form parameters" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'mediaType: multipart/form-data',
          'baseUri: http://myapi.org',
          '/resource:',
          '  post:',
          '    body:',
          '      formParameters:'
          """
          expected = %{"title" => 'Test',
                       "mediaType" => 'multipart/form-data',
                       "baseUri" => 'http://myapi.org',
                       "protocols" => ['HTTP'],
                       "resources" => [%{"relativeUri" => "/resource",
                                         "methods" => [%{"body" => %{"multipart/form-data" => %{"formParameters" => nil}},
                                                         "protocols" => ['HTTP'],
                                                         "method" => "post"
                                                        }],
                                         "relativeUriPathSegments" => ["resource"]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should fail when a parameter uses array syntax with only one type" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  post:',
          '    body: ',
          '      formParameters:',
          '        a: []'
          """

          assert_raise(RamlParseError, ~r(named parameter needs at least one type), fn ->
            parse_string!(str)
          end)
        end

        it "should fail when a parameter uses array syntax with only one type" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  post:',
          '    body: ',
          '      formParameters:',
          '        a:',
          '          - displayName: A',
          '            description: This is A',
          ''
          """

          assert_raise(RamlParseError, ~r(single type for variably typed parameter), fn ->
            parse_string!(str)
          end)
        end

        it "should succeed when dealing with URI parameters with two types" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'mediaType: multipart/form-data',
          'baseUri: http://myapi.org',
          '/resource:',
          '  post:',
          '    body:',
          '      formParameters:',
          '        a:',
          '          - displayName: A',
          '            description: This is A',
          '            type: string',
          '          - displayName: A',
          '            description: This is A',
          '            type: file',
          """

          expected = %{"title" => 'Test',
                       "mediaType" => 'multipart/form-data',
                       "baseUri" => 'http://myapi.org',
                       "protocols" => ['HTTP'],
                       "resources" => [%{"relativeUriPathSegments" => ["resource"],
                                         "relativeUri" => "/resource",
                                         "methods" => [%{"body" => %{"multipart/form-data" => %{"formParameters" => %{"a" => [%{"displayName" => 'A',
                                                                                                                                "description" => 'This is A',
                                                                                                                                "type" => "string"
                                                                                                                               },
                                                                                                                              %{"displayName" => 'A',
                                                                                                                                "description" => 'This is A',
                                                                                                                                "type" => "file"
                                                                                                                               }
                                                                                                                             ]
                                                                                                                     }}},
                                                         "method" => "post",
                                                         "protocols" => ['HTTP']
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should be required when explicitly marked" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: My API',
          '/:',
          '  post:',
          '    body:',
          '      application/x-www-form-urlencoded:',
          '        formParameters:',
          '          formParameter1:',
          '            required: true'
          """
          {:ok, result} = parse_string(str)
          required =
            result
          |> Map.get("resources")
          |> Enum.at(0)
          |> Map.get("methods")
          |> Enum.at(0)
          |> Map.get("body")
          |> Map.get("application/x-www-form-urlencoded")
          |> Map.get("formParameters")
          |> Map.get("formParameter1")
          |> Map.get("required")
          assert required == true
        end
      end

      describe "Named parameters in response headers" do
        it "should succeed with null header" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    responses:',
          '      200:',
          '        headers:'
          """

          expected = %{"title" => 'Test',
                       "baseUri" => 'http://myapi.org',
                       "protocols" => ['HTTP'],
                       "resources" => [%{"relativeUriPathSegments" => ["resource" ],
                                         "relativeUri" => "/resource",
                                         "methods" => [%{"method" => "get",
                                                         "protocols" => ['HTTP'],
                                                         "responses" => %{"200" => %{"headers" => nil}}
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should fail when a parameter uses array syntax with only one type" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    responses:',
          '      200:',
          '        headers:',
          '          a: []'
          """

          assert_raise(RamlParseError, ~r(named parameter needs at least one type), fn ->
            parse_string!(str)
          end)
        end

        it "should fail when a parameter uses array syntax with only one type" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    responses:',
          '      200:',
          '        headers:',
          '          a:',
          '            - displayName: A',
          '              description: This is A',
          ''
          """

          assert_raise(RamlParseError, ~r(single type for variably typed parameter), fn ->
            parse_string!(str)
          end)
        end

        it "should succeed when a parameter uses array syntax with two types" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: Test',
          'baseUri: http://myapi.org',
          '/resource:',
          '  get:',
          '    responses:',
          '      200:',
          '        headers:',
          '           a:',
          '            - displayName: A',
          '              description: This is A',
          '              type: string',
          '            - displayName: A',
          '              description: This is A',
          '              type: file',
          """

          expected = %{"title" => 'Test',
                       "baseUri" => 'http://myapi.org',
                       "protocols" => ['HTTP'],
                       "resources" => [%{"relativeUriPathSegments" => [ "resource" ],
                                         "relativeUri" => "/resource",
                                         "methods" => [%{"method" => "get",
                                                         "protocols" => ['HTTP'],
                                                         "responses" => %{"200" => %{"headers" => %{"a" => [%{"displayName" => 'A',
                                                                                                              "description" => 'This is A',
                                                                                                              "type" => "string"
                                                                                                             },
                                                                                                            %{
                                                                                                              "displayName" => 'A',
                                                                                                              "description" => 'This is A',
                                                                                                              "type" => "file"
                                                                                                            },
                                                                                                           ]
                                                                                                   }}}
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should be required when explicitly marked" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: My API',
          '/:',
          '  get:',
          '    responses:',
          '      200:',
          '        headers:',
          '          header1:',
          '            required: true'
          """
          {:ok, result} = parse_string(str)
          required =
            result
          |> Map.get("resources")
          |> Enum.at(0)
          |> Map.get("methods")
          |> Enum.at(0)
          |> Map.get("responses")
          |> Map.get("200")
          |> Map.get("headers")
          |> Map.get("header1")
          |> Map.get("required")
          assert required == true
        end
      end
    end

    describe "Resources" do
      it "should fail on duplicate absolute URIs" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  /b:',
        '    displayName: B',
        '/a/b:',
        '  displayName: AB'
        """

        assert_raise(RamlParseError, ~r(two resources share same URI \/a\/b), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  /b:',
        '    displayName: B',
        '/a/c:',
        '  displayName: AC'
        """

        expected = %{"title" => 'Test',
                     "resources" => [%{"relativeUriPathSegments" => ["a"],
                                       "relativeUri" => '/a',
                                       "displayName" => 'A',
                                       "resources" => [%{"relativeUriPathSegments" => ["b"],
                                                         "relativeUri" => '/b',
                                                         "displayName" => 'B'
                                                        }]
                                      },
                                     %{"relativeUriPathSegments" => ["a", "c"],
                                       "relativeUri" => '/a/c',
                                       "displayName" => 'AC'
                                      }
                                    ]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed when a method is null" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  get: ~'
        """

        expected = %{"title" => 'Test',
                     "resources" => [%{"relativeUriPathSegments" => ["a"],
                                       "relativeUri" => '/a',
                                       "displayName" => 'A',
                                       "methods" => [%{"method" => "get"}]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should allow resources named like HTTP verbs" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/getSomething:',
        '  displayName: GetSomething',
        '/postSomething:',
        '  displayName: PostSomething',
        '/putSomething:',
        '  displayName: PutSomething',
        '/deleteSomething:',
        '  displayName: DeleteSomething',
        '/headSomething:',
        '  displayName: HeadSomething',
        '/patchSomething:',
        '  displayName: PatchSomething',
        '/optionsSomething:',
        '  displayName: OptionsSomething',
        '/get:',
        '  displayName: Get',
        '/post:',
        '  displayName: Post',
        '/put:',
        '  displayName: Put',
        '/delete:',
        '  displayName: Delete',
        '/head:',
        '  displayName: Head',
        '/patch:',
        '  displayName: Patch',
        '/options:',
        '  displayName: Options'
        """

        expected = %{"title" => 'Test',
                     "resources" => [%{"relativeUriPathSegments" => ["getSomething"],
                                       "relativeUri" => '/getSomething',
                                       "displayName" => 'GetSomething'
                                      },
                                     %{"relativeUriPathSegments" => ["postSomething"],
                                       "relativeUri" => '/postSomething',
                                       "displayName" => 'PostSomething'
                                      },
                                     %{"relativeUriPathSegments" => ["putSomething"],
                                       "relativeUri" => '/putSomething',
                                       "displayName" => 'PutSomething'
                                      },
                                     %{"relativeUriPathSegments" => ["deleteSomething"],
                                       "relativeUri" => '/deleteSomething',
                                       "displayName" => 'DeleteSomething'
                                      },
                                     %{"relativeUriPathSegments" => ["headSomething"],
                                       "relativeUri" => '/headSomething',
                                       "displayName" => 'HeadSomething'
                                      },
                                     %{"relativeUriPathSegments" => ["patchSomething"],
                                       "relativeUri" => '/patchSomething',
                                       "displayName" => 'PatchSomething'
                                      },
                                     %{"relativeUriPathSegments" => ["optionsSomething"],
                                       "relativeUri" => '/optionsSomething',
                                       "displayName" => 'OptionsSomething'
                                      },
                                     %{"relativeUriPathSegments" => ["get"],
                                       "relativeUri" => '/get',
                                       "displayName" => 'Get'
                                      },
                                     %{"relativeUriPathSegments" => ["post"],
                                       "relativeUri" => '/post',
                                       "displayName" => 'Post'
                                      },
                                     %{"relativeUriPathSegments" => ["put"],
                                       "relativeUri" => '/put',
                                       "displayName" => 'Put'
                                      },
                                     %{"relativeUriPathSegments" => ["delete"],
                                       "relativeUri" => '/delete',
                                       "displayName" => 'Delete'
                                      },
                                     %{"relativeUriPathSegments" => ["head"],
                                       "relativeUri" => '/head',
                                       "displayName" => 'Head'
                                      },
                                     %{"relativeUriPathSegments" => ["patch"],
                                       "relativeUri" => '/patch',
                                       "displayName" => 'Patch'
                                      },
                                     %{"relativeUriPathSegments" => ["options"],
                                       "relativeUri" => '/options',
                                       "displayName" => 'Options'
                                      }
                                    ]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should not fail when resource is null" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/:'
        """

        expected = %{"title" => "Test",
                     "resources" => [%{"relativeUriPathSegments" => [],
                                       "relativeUri" => "/"
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "is should fail when resource is a scalar" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/: foo'
        """

        assert_raise(RamlParseError, ~r(resource is not a map), fn ->
          parse_string!(str)
        end)
      end

      it "is should fail when resource is an array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/: foo'
        """

        assert_raise(RamlParseError, ~r(resource is not a map), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "Resource Responses" do
      it "should succeed with arrays as keys" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/foo:',
        '  displayName: A',
        '  get:' ,
        '    description: Blah',
        '    responses:',
        '      [200, 210]:',
        '        description: Blah Blah',
        ''
        """

        assert_raise(RamlParseError, ~r(only scalar map keys are allowed in RAML), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed with null response" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/foo:',
        '  displayName: A',
        '  get:' ,
        '    description: Blah',
        '    responses:',
        '      200:'
        """

        expected = %{"title" => 'Test',
                     "resources" => [%{"displayName" => 'A',
                                       "relativeUri" => '/foo',
                                       "relativeUriPathSegments" => ["foo"],
                                       "methods" => [%{"description" => 'Blah',
                                                       "responses" => %{"200" => nil},
                                                       "method" => 'get'
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if status code is string" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/foo:',
        '  displayName: A',
        '  get:' ,
        '    description: Blah',
        '    responses:',
        '      fail-here:'
        """

        assert_raise(RamlParseError, ~r(each response key must be an integer), fn ->
          parse_string!(str)
        end)
      end

      it "should overwrite existing node with arrays as keys" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/foo:',
        '  displayName: A',
        '  get:' ,
        '    description: Blah',
        '    responses:',
        '      200:',
        '        description: Foo Foo',
        '      [200, 210]:',
        '        description: Blah Blah',
        ''
        """

        assert_raise(RamlParseError, ~r(only scalar map keys are allowed in RAML), fn ->
          parse_string!(str)
        end)
      end

      it "should overwrite arrays as keys with new single node" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/foo:',
        '  displayName: A',
        '  get:' ,
        '    description: Blah',
        '    responses:',
        '      [200, 210]:',
        '        description: Blah Blah',
        '      200:',
        '        description: Foo Foo',
        ''
        """

        assert_raise(RamlParseError, ~r(only scalar map keys are allowed in RAML), fn ->
          parse_string!(str)
        end)
      end

      it "should fail to load a yaml with hash as key" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/foo:',
        '  displayName: A',
        '  get:' ,
        '    description: Blah',
        '    responses:',
        '      {200: Blah}:',
        '        description: Blah Blah',
        ''
        """

        assert_raise(RamlParseError, ~r(only scalar map keys are allowed in RAML), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "Traits at resource level" do
      it 'should succeed when applying traits across !include boundaries' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - customTrait: !include test/assets/customtrait.yml',
        '/: !include test/assets/root.yml'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"customTrait" => %{"displayName" => 'Custom Trait',
                                                       "description" => 'This is a custom trait',
                                                       "responses" => %{"429" => %{"description" => 'API Limit Exceeded'}}
                                                      }}],
                     "resources" => [%{"is" => ["customTrait"],
                                       "displayName" => "Root",
                                       "relativeUri" => "/",
                                       "methods" => [%{"description" => "Root resource",
                                                       "responses" => %{"429" => %{"description" => 'API Limit Exceeded'}},
                                                       "method" => "get"
                                                      }],
                                       "resources" => [%{"is" => ["customTrait"],
                                                         "displayName" => "Another Resource",
                                                         "relativeUri" => "/anotherResource",
                                                         "methods" => [%{"description" => "Another resource",
                                                                         "responses" => %{"429" => %{"description" => 'API Limit Exceeded'}},
                                                                         "method" => "get"
                                                                        }],
                                                         "relativeUriPathSegments" => ["anotherResource"]
                                                        }],
                                       "relativeUriPathSegments" => []
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed when applying multiple traits" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      responses:',
        '        429:',
        '          description: API Limit Exceeded',
        '  - queryable:',
        '      displayName: Queryable',
        '      queryParameters:',
        '        q:',
        '          type: string',
        '/leagues:',
        '  is: [ rateLimited, queryable ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "responses" => %{"429" => %{"description" => 'API Limit Exceeded'}}
                                                      }},
                                  %{"queryable" => %{"displayName" => 'Queryable',
                                                     "queryParameters" => %{"q" => %{"type" => 'string',
                                                                                     "displayName" => "q"
                                                                                    }}
                                                    }
                                   }
                                 ],
                     "resources" => [%{"relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "is" => ['rateLimited', 'queryable'],
                                       "methods" => [%{"method" => 'get',
                                                       "queryParameters" => %{"q" => %{"type" => 'string',
                                                                                       "displayName" => "q"
                                                                                      }},
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'},
                                                                        "429" => %{"description" => 'API Limit Exceeded'}
                                                                       }
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed when applying a trait to a null method" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      responses:',
        '        429:',
        '          description: API Limit Exceeded',
        '/leagues:',
        '  is: [ rateLimited ]',
        '  get:'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "responses" => %{"429" => %{"description" => 'API Limit Exceeded'}}
                                                      }
                                   }],
                     "resources" => [%{"relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "is" => ['rateLimited'],
                                       "methods" => [%{"method" => 'get',
                                                       "responses" => %{"429" => %{"description" => 'API Limit Exceeded'}}
                                                      }]
                                      }]
        }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed when applying multiple traits in a single array entry" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      responses:',
        '        429:',
        '          description: API Limit Exceeded',
        '    queryable:',
        '      displayName: Queryable',
        '      queryParameters:',
        '        q:',
        '          type: string',
        '/leagues:',
        '  is: [ rateLimited, queryable ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "responses" => %{"429" => %{"description" => 'API Limit Exceeded'}}
                                                      },
                                    "queryable" => %{"displayName" => 'Queryable',
                                                     "queryParameters" => %{"q" => %{"type" => 'string',
                                                                                     "displayName" => "q"
                                                                                    }}
                                                    }
                                   }],
                     "resources" => [%{"relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "is" => ['rateLimited', 'queryable'],
                                       "methods" => [%{"method" => 'get',
                                                       "queryParameters" => %{"q" => %{"type" => 'string',
                                                                                       "displayName" => "q"
                                                                                      }},
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'},
                                                                        "429" => %{"description" => 'API Limit Exceeded'}
                                                                       }
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should remove nodes with question mark that are not used" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers?:',
        '        x-header-extra:',
        '          displayName: API Limit Exceeded',
        '/leagues:',
        '  is: [ rateLimited ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers?" => %{"x-header-extra" => %{"displayName" => "API Limit Exceeded",
                                                                                             "type" => "string"
                                                                                            }}
                                                      }}],
                     "resources" => [%{"relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "is" => ['rateLimited'],
                                       "methods" => [%{"method" => 'get',
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}}
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed if trait is missing displayName property" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      responses:',
        '        503:',
        '          description: Server Unavailable. Check Your Rate Limits.',
        '/:',
        '  is: [ rateLimited: { parameter: value } ]'
        """

        expected = %{"title" => "Test",
                     "traits" => [%{"rateLimited" => %{"responses" => %{"503" => %{"description" => "Server Unavailable. Check Your Rate Limits."}}}}],
                     "resources" => [%{"relativeUriPathSegments" => [],
                                       "is" => [%{"rateLimited" => %{"parameter" => "value"}}],
                                       "relativeUri" => "/"
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if traits value is scalar" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits: foo',
        '/:',
        '  is: [ rateLimited: { parameter: value } ]'
        """
        assert_raise(RamlParseError, ~r(invalid traits definition, it must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if traits value is dictionary" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  trait1:',
        '    displayName: foo',
        '/:',
        '  is: [ rateLimited: { parameter: value } ]'
        """
        assert_raise(RamlParseError, ~r(invalid traits definition, it must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if use property is not an array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/:',
        '  is: throttled ]'
        """
        assert_raise(RamlParseError, ~r(property 'is' must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should fail on invalid trait name" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      responses:',
        '        503:',
        '          description: Server Unavailable. Check Your Rate Limits.',
        '/:',
        '  is: [ throttled, rateLimited: { parameter: value } ]'
        """
        assert_raise(RamlParseError, ~r(there is no trait named throttled), fn ->
          parse_string!(str)
        end)
      end

      it 'should allow using "use" as a resource name' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://www.api.com/{version}/{company}',
        'version: v1.1',
        '/users:',
        ' displayName: Tags',
        ' get:',
        ' post:',
        ' /{userid}:',
        '  displayName: Search'
        """

        expected = %{"title" => 'Test',
                     "baseUri" => 'http://www.api.com/{version}/{company}',
                     "version" => 'v1.1',
                     "protocols" => ['HTTP'],
                     "resources" => [%{"displayName" => 'Tags',
                                       "relativeUri" => '/users',
                                       "methods" => [%{"protocols" => ['HTTP'],
                                                       "method" => 'get'
                                                      },
                                                     %{"protocols" => ['HTTP'],
                                                       "method" => 'post'
                                                      }
                                                    ],
                                       "resources" => [%{"displayName" => 'Search',
                                                         "relativeUri" => '/{userid}',
                                                         "relativeUriPathSegments" => ["{userid}"],
                                                         "uriParameters" => %{"userid" => %{"type" => "string",
                                                                                            "required" => true,
                                                                                            "displayName" => "userid"
                                                                                           }}
                                                        }],
                                       "relativeUriPathSegments" => ["users"]
                                      }],
                     "baseUriParameters" => %{"version" => %{"type" => "string",
                                                             "required" => true,
                                                             "displayName" => "version",
                                                             "enum" => ["v1.1"]
                                                            },
                                              "company" => %{"type" => "string",
                                                             "required" => true,
                                                             "displayName" => "company"
                                                            }
                                             },
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should not add intermediate structures in optional keys for missing properties" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers:',
        '        If-None-Match?:',
        '          description: |',
        '            If-None-Match headers ensure that you don’t retrieve unnecessary data',
        '            if you already have the most current version on-hand.',
        '          type: string',
        '        On-Behalf-Of?:',
        '          description: |',
        '            Used for enterprise administrators to make API calls on behalf of their',
        '            managed users. To enable this functionality, please contact us with your',
        '            API key.',
        '          type: string',
        '/leagues:',
        '  is: [ rateLimited ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers" => %{"If-None-Match?" => %{"description" => 'If-None-Match headers ensure that you don’t retrieve unnecessary data\nif you already have the most current version on-hand.\n',
                                                                                            "type" => 'string',
                                                                                            "displayName" => "If-None-Match"
                                                                                           },
                                                                      'On-Behalf-Of?' => %{"description" => 'Used for enterprise administrators to make API calls on behalf of their\nmanaged users. To enable this functionality, please contact us with your\nAPI key.\n',
                                                                                           "type" => 'string',
                                                                                           "displayName" => "On-Behalf-Of"
                                                                                          }
                                                                     }
                                                      }}],
                     "resources" => [%{"is" => ['rateLimited'],
                                       "relativeUriPathSegments" => [ "leagues" ],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"headers" => %{},
                                                       "method" => 'get',
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}}
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should allow dictionary keys as names of traits" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers?:',
        '        If-None-Match?:',
        '          description: |',
        '            If-None-Match headers ensure that you don’t retrieve unnecessary data',
        '            if you already have the most current version on-hand.',
        '          type: string',
        '        On-Behalf-Of?:',
        '          description: |',
        '            Used for enterprise administrators to make API calls on behalf of their',
        '            managed users. To enable this functionality, please contact us with your',
        '            API key.',
        '          type: string',
        '/leagues:',
        '  is: [ rateLimited: {} ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers?" => %{"If-None-Match?" => %{"description" => 'If-None-Match headers ensure that you don’t retrieve unnecessary data\nif you already have the most current version on-hand.\n',
                                                                                             "type" => 'string',
                                                                                             "displayName" => "If-None-Match"
                                                                                            },
                                                                       'On-Behalf-Of?' => %{"description" => 'Used for enterprise administrators to make API calls on behalf of their\nmanaged users. To enable this functionality, please contact us with your\nAPI key.\n',
                                                                                            "type" => 'string',
                                                                                            "displayName" => "On-Behalf-Of"
                                                                                           }
                                                                      }
                                                      }}],
                     "resources" => [%{"is" => [%{"rateLimited" => %{}}],
                                       "relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"method" => 'get',
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}}
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should allow parameters in a trait usage" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers?:',
        '        If-None-Match?:',
        '          description: |',
        '            If-None-Match headers ensure that you don’t retrieve unnecessary data',
        '            if you already have the most current version on-hand.',
        '          type: string',
        '        On-Behalf-Of?:',
        '          description: |',
        '            Used for enterprise administrators to make API calls on behalf of their',
        '            managed users. To enable this functionality, please contact us with your',
        '            API key.',
        '          type: string',
        '      queryParameters:',
        '        param1: {description: <<param1>>}',
        '/leagues:',
        '  is: [ rateLimited: { param1: value1 } ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers?" => %{"If-None-Match?" => %{"description" => 'If-None-Match headers ensure that you don’t retrieve unnecessary data\nif you already have the most current version on-hand.\n',
                                                                                             "type" => 'string',
                                                                                             "displayName" => "If-None-Match"
                                                                                            },
                                                                       'On-Behalf-Of?' => %{"description" => 'Used for enterprise administrators to make API calls on behalf of their\nmanaged users. To enable this functionality, please contact us with your\nAPI key.\n',
                                                                                            "type" => 'string',
                                                                                            "displayName" => "On-Behalf-Of"
                                                                                           }
                                                                      },
                                                       "queryParameters" => %{"param1" => %{"displayName" => 'param1',
                                                                                            "description" => '<<param1>>',
                                                                                            "type" => 'string'
                                                                                           }}
                                                      }}],
                     "resources" => [%{"is" => [%{"rateLimited" => %{"param1" => 'value1'}}],
                                       "relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"method" => 'get',
                                                       "queryParameters" => %{"param1" => %{"displayName" => 'param1',
                                                                                            "description" => 'value1',
                                                                                            "type" => 'string'
                                                                                           }
                                                                             },
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}}
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should reject parameters whose value is an array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited (<<param1>>-<<param2>>)',
        '      headers?:',
        '        If-None-Match?:',
        '          description: |',
        '            If-None-Match headers ensure that you don’t retrieve unnecessary data',
        '            if you already have the most current version on-hand.',
        '          type: string',
        '        On-Behalf-Of?:',
        '          description: |',
        '            Used for enterprise administrators to make API calls on behalf of their',
        '            managed users. To enable this functionality, please contact us with your',
        '            API key.',
        '          type: string',
        '/leagues:',
        '  is: [ rateLimited: { param1: ["value1"], param2: value2} ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """
        assert_raise(RamlParseError, ~r(parameter value must be a scalar), fn ->
          parse_string!(str)
        end)
      end

      it "should reject parameters whose value is a map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '/leagues:',
        '  is: [ rateLimited: { param1: {key: "value"}, param2: value} ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """
        assert_raise(RamlParseError, ~r(parameter value must be a scalar), fn ->
          parse_string!(str)
        end)
      end

      it "should reject trait with missing provided parameters" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers:',
        '        Authorization:',
        '          description: <<lalalalala>> <<pepepepepepep>>',
        '/leagues:',
        '  is: [ rateLimited: { param1: value1, param2: value2} ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        assert_raise(RamlParseError, ~r(value was not provided for parameter: lalalalala), fn ->
          parse_string!(str)
        end)
      end

      it "should apply parameters in traits" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers:',
        '        Authorization:',
        '          description: <<param1>> <<param2>>',
        '/leagues:',
        '  is: [ rateLimited: { param1: "value1", param2: "value2"} ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers" => %{"Authorization" => %{"description" => '<<param1>> <<param2>>',
                                                                                           "displayName" => "Authorization",
                                                                                           "type" => "string"
                                                                                          }}
                                                      }}],
                     "resources" => [%{"is" => [ %{ "rateLimited" => %{"param1" => 'value1', "param2" => 'value2'}}],
                                       "relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"headers" => %{"Authorization" => %{"description" => 'value1 value2',
                                                                                           "displayName" => "Authorization",
                                                                                           "type" => "string"
                                                                                          }},
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}},
                                                       "method" => 'get'
                                                      }]
                                      }]
        }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should apply parameters in traits in each occurrence" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers:',
        '        Authorization:',
        '          description: <<param1>> <<param2>><<param1>> <<param2>><<param1>> <<param2>><<param1>> <<param2>><<param1>> <<param2>><<param1>> <<param2>>',
        '        X-Random-Header:',
        '          description: <<param2>><<param2>><<param2>>',
        '        <<param2>><<param2>>:',
        '          description: <<param1>>',
        '/leagues:',
        '  is: [ rateLimited: { param1: "value1", param2: "value2"} ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """
        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers" => %{"Authorization" => %{"description" => '<<param1>> <<param2>><<param1>> <<param2>><<param1>> <<param2>><<param1>> <<param2>><<param1>> <<param2>><<param1>> <<param2>>',
                                                                                           "displayName" => "Authorization",
                                                                                           "type" => "string"
                                                                                          },
                                                                      "X-Random-Header" => %{"description" => '<<param2>><<param2>><<param2>>',
                                                                                             "displayName" => "X-Random-Header",
                                                                                             "type" => "string"
                                                                                            },
                                                                      "<<param2>><<param2>>" => %{"description" => '<<param1>>',
                                                                                                  "displayName" => "<<param2>><<param2>>",
                                                                                                  "type" => "string"
                                                                                                 }
                                                                     }
                                                      }}],
                     "resources" => [%{"is" => [%{"rateLimited" => %{"param1" => 'value1',
                                                                     "param2" => 'value2'}}],
                                       "relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"headers" => %{"Authorization" => %{"description" => 'value1 value2value1 value2value1 value2value1 value2value1 value2value1 value2',
                                                                                           "displayName" => "Authorization",
                                                                                           "type" => "string"
                                                                                          },
                                                                      "X-Random-Header" => %{"description" => 'value2value2value2',
                                                                                             "displayName" => "X-Random-Header",
                                                                                             "type" => "string"
                                                                                            },
                                                                      "value2value2" => %{"description" => 'value1',
                                                                                          "displayName" => "value2value2",
                                                                                          "type" => "string"
                                                                                         }
                                                                     },
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}},
                                                       "method" => 'get'
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should apply parameters in keys in traits" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers:',
        '        <<header>>:',
        '          description: <<param1>> <<param2>>',
        '/leagues:',
        '  is: [ rateLimited: { header: "Authorization", param1: "value1", param2: "value2"} ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers" => %{"<<header>>" => %{"description" => '<<param1>> <<param2>>',
                                                                                        "displayName" => "<<header>>",
                                                                                        "type" => "string"
                                                                                       }}
                                                      }}],
                     "resources" => [%{"is" => [%{"rateLimited" => %{"header" => "Authorization",
                                                                     "param1" => 'value1',
                                                                     "param2" => 'value2'}}],
                                       "relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"headers" => %{"Authorization" => %{"description" => 'value1 value2',
                                                                                           "displayName" => "Authorization",
                                                                                           "type" => "string"
                                                                                          }},
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}},
                                                       "method" => 'get'
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should apply traits in all methods" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers:',
        '        <<header>>:',
        '          description: <<param1>> <<param2>>',
        '/leagues:',
        '  is: [ rateLimited: { header: "Authorization", param1: "value1", param2: "value2"} ]',
        '  get:',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues',
        '  post:',
        '    responses:',
        '      200:',
        '        description: creates a new league'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers" => %{"<<header>>" => %{"description" => '<<param1>> <<param2>>',
                                                                                        "displayName" => "<<header>>",
                                                                                        "type" => "string"
                                                                                       }}
                                                      }}],
                     "resources" => [%{"is" => [%{"rateLimited" => %{"header" => "Authorization",
                                                                     "param1" => 'value1',
                                                                     "param2" => 'value2'
                                                                    }}],
                                       "relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"headers" => %{"Authorization" => %{"description" => 'value1 value2',
                                                                                           "displayName" => "Authorization",
                                                                                           "type" => "string"
                                                                                          }},
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}},
                                                       "method" => 'get'
                                                      },
                                                     %{"headers" => %{"Authorization" => %{"description" => 'value1 value2',
                                                                                           "displayName" => "Authorization",
                                                                                           "type" => "string"
                                                                                          }},
                                                       "responses" => %{"200" => %{"description" => 'creates a new league'}},
                                                       "method" => 'post'
                                                      }
                                                    ]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end
    end

    describe "Traits at method level" do
      it 'should succeed when applying traits across !include boundaries' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - customTrait: !include test/assets/customtrait.yml',
        '/: !include test/assets/traitsAtResourceLevel.yml'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"customTrait" => %{"displayName" => 'Custom Trait',
                                                       "description" => 'This is a custom trait',
                                                       "responses" => %{"429" => %{"description" => 'API Limit Exceeded'}}
                                                      }}],
                     "resources" => [%{"displayName" => "Root",
                                       "relativeUriPathSegments" => [],
                                       "relativeUri" => "/",
                                       "methods" => [%{"is" => ["customTrait"],
                                                       "responses" => %{"429" => %{"description" => 'API Limit Exceeded'}},
                                                       "description" => "Root resource",
                                                       "method" => "get"
                                                      }],
                                       "resources" => [%{"relativeUriPathSegments" => ["anotherResource"],
                                                         "relativeUri" => "/anotherResource",
                                                         "displayName" => "Another Resource",
                                                         "methods" => [%{"is" => ["customTrait"],
                                                                         "description" => "Another resource",
                                                                         "method" => "get",
                                                                         "responses" => %{"429" => %{"description" => 'API Limit Exceeded'}}
                                                                        }]
                                                        }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed when applying multiple traits" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      responses:',
        '        429:',
        '          description: API Limit Exceeded',
        '  - queryable:',
        '      displayName: Queryable',
        '      queryParameters:',
        '        q:',
        '           type: string',
        '/leagues:',
        '  get:',
        '    is: [ rateLimited, queryable ]',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """
        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "responses" => %{"429" => %{"description" => 'API Limit Exceeded'}}
                                                      }},
                                  %{"queryable" => %{"displayName" => 'Queryable',
                                                     "queryParameters" => %{"q" => %{"type" => 'string',
                                                                                     "displayName" => "q"
                                                                                    }}
                                                    }}
                                 ],
                     "resources" => [%{"relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"is" => ['rateLimited', 'queryable'],
                                                       "method" => 'get',
                                                       "queryParameters" => %{"q" => %{"type" => 'string',
                                                                                       "displayName" => "q"
                                                                                      }},
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'},
                                                                        "429" => %{"description" => 'API Limit Exceeded'}
                                                                       }
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should remove nodes with question mark that are not used" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers?:',
        '        x-header-extra:',
        '          displayName: API Limit Exceeded',
        '/leagues:',
        '  get:',
        '    is: [ rateLimited ]',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """
        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers?" => %{"x-header-extra" => %{"displayName" => "API Limit Exceeded",
                                                                                             "type" => "string"
                                                                                            }}
                                                      }}],
                     "resources" => [%{"relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"is" => ['rateLimited'],
                                                       "method" => 'get',
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}}
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed if trait is missing displayName property" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      responses:',
        '        503:',
        '          description: Server Unavailable. Check Your Rate Limits.'
        """
        expected = %{"title" => "Test",
                     "traits" => [%{"rateLimited" => %{"responses" => %{"503" => %{"description" => "Server Unavailable. Check Your Rate Limits."}}}}]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if use property is not an array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/:',
        '  get:',
        '    is: throttled ]'
        """

        assert_raise(RamlParseError, ~r(property 'is' must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should fail on invalid trait name" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      responses:',
        '        503:',
        '          description: Server Unavailable. Check Your Rate Limits.',
        '/:',
        '  get:',
        '    is: [ throttled, rateLimited: { parameter: value } ]'
        """
        assert_raise(RamlParseError, ~r(there is no trait named throttled), fn ->
          parse_string!(str)
        end)
      end

      it "should not add intermediate structures in optional keys for missing properties" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers:',
        '        If-None-Match?:',
        '          description: |',
        '            If-None-Match headers ensure that you don’t retrieve unnecessary data',
        '            if you already have the most current version on-hand.',
        '          type: string',
        '        On-Behalf-Of?:',
        '          description: |',
        '            Used for enterprise administrators to make API calls on behalf of their',
        '            managed users. To enable this functionality, please contact us with your',
        '            API key.',
        '          type: string',
        '/leagues:',
        '  get:',
        '    is: [ rateLimited ]',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """
        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers" => %{"If-None-Match?" => %{"description" => 'If-None-Match headers ensure that you don’t retrieve unnecessary data\nif you already have the most current version on-hand.\n',
                                                                                            "type" => 'string',
                                                                                            "displayName" => "If-None-Match"
                                                                                           },
                                                                      'On-Behalf-Of?' => %{"description" => 'Used for enterprise administrators to make API calls on behalf of their\nmanaged users. To enable this functionality, please contact us with your\nAPI key.\n',
                                                                                           "type" => 'string',
                                                                                           "displayName" => "On-Behalf-Of"
                                                                                          }
                                                                     }
                                                      }}],
                     "resources" => [%{"relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"is" => ['rateLimited'],
                                                       "headers" => %{},
                                                       "method" => 'get',
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}}
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should allow dictionary keys as names of traits" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers?:',
        '        If-None-Match?:',
        '          description: |',
        '            If-None-Match headers ensure that you don’t retrieve unnecessary data',
        '            if you already have the most current version on-hand.',
        '          type: string',
        '        On-Behalf-Of?:',
        '          description: |',
        '            Used for enterprise administrators to make API calls on behalf of their',
        '            managed users. To enable this functionality, please contact us with your',
        '            API key.',
        '          type: string',
        '/leagues:',
        '  get:',
        '    is: [ rateLimited: {} ]',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """
        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers?" => %{"If-None-Match?" => %{"description" => 'If-None-Match headers ensure that you don’t retrieve unnecessary data\nif you already have the most current version on-hand.\n',
                                                                                             "type" => 'string',
                                                                                             "displayName" => "If-None-Match"
                                                                                            },
                                                                       'On-Behalf-Of?' => %{"description" => 'Used for enterprise administrators to make API calls on behalf of their\nmanaged users. To enable this functionality, please contact us with your\nAPI key.\n',
                                                                                            "type" => 'string',
                                                                                            "displayName" => "On-Behalf-Of"
                                                                                           }
                                                                      }
                                                      }}],
                     "resources" => [%{"relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"is" => [%{"rateLimited" => %{}}],
                                                       "method" => 'get',
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}}
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should allow parameters in a trait usage" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers?:',
        '        If-None-Match?:',
        '          description: |',
        '            If-None-Match headers ensure that you don’t retrieve unnecessary data',
        '            if you already have the most current version on-hand.',
        '          type: string',
        '        On-Behalf-Of?:',
        '          description: |',
        '            Used for enterprise administrators to make API calls on behalf of their',
        '            managed users. To enable this functionality, please contact us with your',
        '            API key.',
        '          type: string',
        '      queryParameters:',
        '        param1:',
        '          description: <<param1>>',
        '/leagues:',
        '  get:',
        '    is: [ rateLimited: { param1: value1 } ]',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """
        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers?" => %{"If-None-Match?" => %{"description" => 'If-None-Match headers ensure that you don’t retrieve unnecessary data\nif you already have the most current version on-hand.\n',
                                                                                             "type" => 'string',
                                                                                             "displayName" => "If-None-Match"
                                                                                            },
                                                                       'On-Behalf-Of?' => %{"description" => 'Used for enterprise administrators to make API calls on behalf of their\nmanaged users. To enable this functionality, please contact us with your\nAPI key.\n',
                                                                                            "type" => 'string',
                                                                                            "displayName" => "On-Behalf-Of"
                                                                                           }
                                                                      },
                                                       "queryParameters" => %{"param1" => %{"displayName" => 'param1',
                                                                                            "description" => '<<param1>>',
                                                                                            "type" => 'string'
                                                                                           }
                                                                             }
                                                      }}],
                     "resources" => [%{"relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"is" => [%{"rateLimited" => %{"param1" => 'value1'}}],
                                                       "method" => 'get',
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}},
                                                       "queryParameters" => %{"param1" => %{"displayName" => 'param1',
                                                                                            "description" => 'value1',
                                                                                            "type" => 'string'
                                                                                           }}
                                                      }]
                                      }]
        }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should reject parameters whose value is an array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers?:',
        '        If-None-Match?:',
        '          description: |',
        '            If-None-Match headers ensure that you don’t retrieve unnecessary data',
        '            if you already have the most current version on-hand.',
        '          type: string',
        '        On-Behalf-Of?:',
        '          description: |',
        '            Used for enterprise administrators to make API calls on behalf of their',
        '            managed users. To enable this functionality, please contact us with your',
        '            API key.',
        '          type: string',
        '/leagues:',
        '  get:',
        '    is: [ rateLimited: { param1: ["string"], param2: value} ]',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        assert_raise(RamlParseError, ~r(parameter value must be a scalar), fn ->
          parse_string!(str)
        end)
      end
      it "should reject parameters whose value is a map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '/leagues:',
        '  get:',
        '    is: [ rateLimited: { param1: {key: "value"}, param2: value} ]',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        assert_raise(RamlParseError, ~r(parameter value must be a scalar), fn ->
          parse_string!(str)
        end)
      end

      it "should reject trait with missing provided parameters" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers:',
        '        Authorization:',
        '          description: <<lalalalala>> <<pepepepepepep>>',
        '/leagues:',
        '  get:',
        '    is: [ rateLimited: { param1: value1, param2: value2} ]',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        assert_raise(RamlParseError, ~r(value was not provided for parameter: lalalalala), fn ->
          parse_string!(str)
        end)
      end

      it "should apply parameters in traits" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers:',
        '        Authorization:',
        '          description: <<param1>> <<param2>>',
        '/leagues:',
        '  get:',
        '    is: [ rateLimited: { param1: "value1", param2: "value2"} ]',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """

        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers" => %{"Authorization" => %{"description" => '<<param1>> <<param2>>',
                                                                                           "displayName" => "Authorization",
                                                                                           "type" => "string"
                                                                                          }}
                                                      }}],
                     "resources" => [%{"relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"is" => [%{"rateLimited" => %{"param1" => 'value1',
                                                                                     "param2" => 'value2'
                                                                                    }}],
                                                       "headers" => %{"Authorization" => %{"description" => 'value1 value2',
                                                                                           "displayName" => "Authorization",
                                                                                           "type" => "string"
                                                                                          }},
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}},
                                                       "method" => 'get'
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should apply parameters in keys in traits" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - rateLimited:',
        '      displayName: Rate Limited',
        '      headers:',
        '        <<header>>:',
        '          description: <<param1>> <<param2>>',
        '/leagues:',
        '  get:',
        '    is: [ rateLimited: { header: "Authorization", param1: "value1", param2: "value2"} ]',
        '    responses:',
        '      200:',
        '        description: Retrieve a list of leagues'
        """
        expected = %{"title" => 'Test',
                     "traits" => [%{"rateLimited" => %{"displayName" => 'Rate Limited',
                                                       "headers" => %{"<<header>>" => %{"description" => '<<param1>> <<param2>>',
                                                                                        "displayName" => "<<header>>",
                                                                                        "type" => "string"
                                                                                       }}
                                                      }}],
                     "resources" => [%{"relativeUriPathSegments" => ["leagues"],
                                       "relativeUri" => '/leagues',
                                       "methods" => [%{"is" => [%{"rateLimited" => %{"header" => "Authorization",
                                                                                     "param1" => 'value1',
                                                                                     "param2" => 'value2'}}],
                                                       "headers" => %{"Authorization" => %{"description" => 'value1 value2',
                                                                                           "displayName" => "Authorization",
                                                                                           "type" => "string"
                                                                                          }},
                                                       "responses" => %{"200" => %{"description" => 'Retrieve a list of leagues'}},
                                                       "method" => 'get'
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end
    end

    describe "Resource Types" do
      it "should allow resourceTypes key at root level" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection',
        '      description: The collection of <<resourcePathName>>',
        '      get:',
        '        description: Get all <<resourcePathName>>, optionally filtered',
        '      post:',
        '        description: Create a new <<resourcePathName | !singularize>>',
        '/:',
        '  displayName: Root'
        """

        expected = %{"title" => 'Test',
                     "resourceTypes" => [%{"collection" => %{"displayName" => 'Collection',
                                                             "description" => 'The collection of <<resourcePathName>>',
                                                             "get" => %{"description" => 'Get all <<resourcePathName>>, optionally filtered'},
                                                             "post" => %{"description" => 'Create a new <<resourcePathName | !singularize>>'}
                                                            }}],
                     "resources" => [%{"relativeUriPathSegments" => [],
                                       "displayName" => "Root",
                                       "relativeUri" => "/"
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should allow resourceTypes array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection',
        '      description: The collection of <<resourcePathName>>',
        '      get:',
        '        description: Get all <<resourcePathName>>, optionally filtered',
        '      post:',
        '        description: Create a new <<resourcePathName | !singularize>>',
        '  - item:',
        '      displayName: Item',
        '      description: A single <<resourcePathName>>',
        '      get:',
        '        description: Get a <<resourcePathName | !singularize>>',
        '      post:',
        '        description: Create a new <<resourcePathName | !singularize>>',
        '      patch:',
        '        description: Update a <<resourcePathName | !singularize>>',
        '      delete:',
        '        description: Update a <<resourcePathName | !singularize>>',
        '/:',
        '  displayName: Root'
        """

        expected = %{"title" => 'Test',
                     "resourceTypes" => [%{"collection" => %{"displayName" => 'Collection',
                                                             "description" => 'The collection of <<resourcePathName>>',
                                                             "get" => %{"description" => 'Get all <<resourcePathName>>, optionally filtered'},
                                                             "post" => %{"description" => 'Create a new <<resourcePathName | !singularize>>'}
                                                            }},
                                         %{"item" => %{"displayName" => 'Item',
                                                       "description" => 'A single <<resourcePathName>>',
                                                       "get" => %{"description" => 'Get a <<resourcePathName | !singularize>>'},
                                                       "post" => %{"description" => 'Create a new <<resourcePathName | !singularize>>'},
                                                       "patch" => %{"description" => 'Update a <<resourcePathName | !singularize>>'},
                                                       "delete" => %{"description" => 'Update a <<resourcePathName | !singularize>>'}
                                                      }}
                                        ],
                     "resources" => [%{"relativeUriPathSegments" => [],
                                       "displayName" => "Root",
                                       "relativeUri" => "/"
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if resourceTypes value is scalar" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes: foo',
        '/:'
        """
        assert_raise(RamlParseError, ~r(invalid resourceTypes definition, it must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if resourceTypes value is dictionary" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  type1:',
        '    displayName: foo',
        '/:'
        """
        assert_raise(RamlParseError, ~r(invalid resourceTypes definition, it must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if type is an array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection',
        '      description: The collection of <<resourcePathName>>',
        '      get:',
        '        description: Get all <<resourcePathName>>, optionally filtered',
        '      post:',
        '        description: Create a new <<resourcePathName | !singularize>>',
        '/:',
        '  type: [ foo ]'
        """
        assert_raise(RamlParseError, ~r(property 'type' must be a string or a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if resource is of a missing type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection',
        '      description: The collection of <<resourcePathName>>',
        '      get:',
        '        description: Get all <<resourcePathName>>, optionally filtered',
        '      post:',
        '        description: Create a new <<resourcePathName | !singularize>>',
        '/:',
        '  type: invalidType'
        """
        assert_raise(RamlParseError, ~r(there is no resource type named invalidType), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed if resource type is missing displayName" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      description: The collection of Blah',
        '/:',
        '  type: collection'
        """
        expected = %{"title" => "Test",
                     "resourceTypes" => [%{"collection" => %{"description" => "The collection of Blah"}}],
                     "resources" => [%{"description" => "The collection of Blah",
                                       "type" => "collection",
                                       "relativeUri" => "/",
                                       "relativeUriPathSegments" => [],
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if resource type is null" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection: null',
        '  -',
        '/:'
        """
        assert_raise(RamlParseError, ~r(invalid resourceType definition, it must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if resource type is null" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  -',
        '/:'
        """
        assert_raise(RamlParseError, ~r(invalid resourceType definition, it must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if resource type is not map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - string',
        '/:'
        """
        assert_raise(RamlParseError, ~r(invalid resourceType definition, it must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if resource type declares a sub resource" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection',
        '      description: The collection of <<resourcePathName>>',
        '      /bar:',
        '/:',
        '  type: collection'
        """
        assert_raise(RamlParseError, ~r(resource type cannot define child resources), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if type dictionary has no keys" do
        str = """
        '#%RAML 0.8',
        'title: titulo',
        'baseUri: http://api.com',
        '/resource:',
        '  type: {}'
        """
        assert_raise(RamlParseError, ~r(resource type name must be provided), fn ->
          parse_string(str)
        end)
      end

      it "should fail if a resource type inherits from a missing type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      type: missing',
        '      displayName: Collection',
        '      description: This resourceType should be used for any collection of items',
        '/:',
        '  type: collection'
        """
        assert_raise(RamlParseError, ~r(there is no resource type named missing), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if a resource type applies a missing trait" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - foo:',
        '     displayName: Foo',
        'resourceTypes:',
        '  - collection:',
        '     is: [foo, bar]',
        '     displayName: Collection',
        '     description: This resourceType should be used for any collection of items',
        '/:',
        '  type: collection'
        """
        assert_raise(RamlParseError, ~r(there is no trait named bar), fn ->
          parse_string!(str)
        end)
      end

      it 'should fail if a resource type\'s method applies a missing trait' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - foo:',
        '     displayName: Foo',
        'resourceTypes:',
        '  - collection:',
        '     displayName: Collection',
        '     description: This resourceType should be used for any collection of items',
        '     get:',
        '       is: [foo, bar]',
        '/:',
        '  type: collection'
        """
        assert_raise(RamlParseError, ~r(there is no trait named bar), fn ->
          parse_string!(str)
        end)
      end

      it "should apply a resource type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection',
        '      description: This resourceType should be used for any collection of items',
        '      post:',
        '       body:',
        '/:',
        '  type: collection'
        """

        expected = %{"title" => "Test",
                     "resourceTypes" => [%{"collection" => %{"displayName" => "Collection",
                                                             "description" => "This resourceType should be used for any collection of items",
                                                             "post" => %{"body" => nil}
                                                            }
                                          }],
                     "resources" => [%{"relativeUriPathSegments" => [],
                                       "description" => "This resourceType should be used for any collection of items",
                                       "type" => "collection",
                                       "relativeUri" => "/",
                                       "methods" => [%{"method" => "post",
                                                       "body" => nil
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should apply a resource type if type key is map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection',
        '      description: This resourceType should be used for any collection of items',
        '      post:',
        '       body:',
        '/:',
        '  type: { collection }'
        """
        expected = %{"title" => "Test",
                     "resourceTypes" => [%{"collection" => %{"displayName" => "Collection",
                                                             "description" => "This resourceType should be used for any collection of items",
                                                             "post" => %{"body" => nil}
                                                            }
                                          }],
                     "resources" => [%{"relativeUriPathSegments" => [],
                                       "description" => "This resourceType should be used for any collection of items",
                                       "type" => %{"collection" => nil},
                                       "relativeUri" => "/",
                                       "methods" => [%{"method" => "post",
                                                       "body" => nil
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should apply a resource type if type key is map and type name is map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection (<<foo>>)',
        '      description: This resourceType should be used for any collection of items',
        '      post:',
        '       body:',
        '/:',
        '  type: { collection: { foo: bar } }'
        """
        expected = %{"title" => "Test",
                     "resourceTypes" => [%{"collection" => %{"displayName" => "Collection (<<foo>>)",
                                                             "description" => "This resourceType should be used for any collection of items",
                                                             "post" => %{"body" => nil}
                                                            }}],
                     "resources" => [%{"description" => "This resourceType should be used for any collection of items",
                                       "type" => %{"collection" => %{"foo" => "bar"}},
                                       "relativeUri" => "/",
                                       "relativeUriPathSegments" => [],
                                       "methods" => [%{"method" => "post",
                                                       "body" => nil
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if type property has more than one key" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection',
        '      description: This resourceType should be used for any collection of items',
        '      post:',
        '       body:',
        '/:',
        '  type: { collection: { foo: bar }, collection }'
        """
        assert_raise(RamlParseError, ~r(a resource or resourceType can inherit from a single resourceType), fn ->
          parse_string!(str)
        end)
      end

      it "should apply a resource type to a type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - post:',
        '      type: get',
        '      displayName: Collection post',
        '      description: This resourceType should be used for any collection of items post',
        '      post:',
        '       body:',
        '  - get:',
        '      displayName: Collection get',
        '      description: This resourceType should be used for any collection of items get',
        '      get:',
        '       body:',
        '/:',
        '  type: post'
        """

        expected = %{"title" => "Test",
                     "resourceTypes" => [%{"post" => %{"type" => "get",
                                                       "displayName" => "Collection post",
                                                       "description" => "This resourceType should be used for any collection of items post",
                                                       "post" =>%{"body" => nil}
                                                      }},
                                         %{"get" => %{"displayName" => "Collection get",
                                                      "description" => "This resourceType should be used for any collection of items get",
                                                      "get" => %{"body" => nil}
                                                     }}
                                        ],
                     "resources" => [%{"description" => "This resourceType should be used for any collection of items post",
                                       "type" => "post",
                                       "relativeUri" => "/",
                                       "relativeUriPathSegments" => [],
                                       "methods" => [%{"body" => nil,
                                                       "method" => "get"
                                                      },
                                                     %{"body" => nil,
                                                       "method" => "post"
                                                      }
                                                    ]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should resolve a 3 level deep inheritance chain" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - post:',
        '      type: get',
        '      displayName: Collection post',
        '      description: This resourceType should be used for any collection of items post',
        '      post:',
        '       body:',
        '  - get:',
        '      type: delete',
        '      displayName: Collection get',
        '      description: This resourceType should be used for any collection of items get',
        '      get:',
        '       body:',
        '  - delete:',
        '      displayName: Collection delete',
        '      description: This resourceType should be used for any collection of items delete',
        '      delete:',
        '       body:',
        '/:',
        '  type: post'
        """

        expected = %{"title" => "Test",
                     "resourceTypes" => [%{"post" => %{"type" => "get",
                                                       "displayName" => "Collection post",
                                                       "description" => "This resourceType should be used for any collection of items post",
                                                       "post" => %{"body" => nil}
                                                      }},
                                         %{"get" => %{"type" => "delete",
                                                      "displayName" => "Collection get",
                                                      "description" => "This resourceType should be used for any collection of items get",
                                                      "get" => %{"body" => nil}
                                                     }},
                                         %{"delete" => %{"displayName" => "Collection delete",
                                                         "description" => "This resourceType should be used for any collection of items delete",
                                                         "delete" => %{"body" => nil}
                                                        }}
                                        ],
                     "resources" => [%{"type" => "post",
                                       "relativeUri" => "/",
                                       "relativeUriPathSegments" => [],
                                       "description" => "This resourceType should be used for any collection of items post",
                                       "methods" => [%{"body" => nil,
                                                       "method" => "delete"
                                                      },
                                                     %{"body" => nil,
                                                       "method" => "get"
                                                      },
                                                     %{"body" => nil,
                                                       "method" => "post"
                                                      }
                                                    ]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should apply parameters to a resource type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection',
        '      description: <<foo>> resourceType should be used for any collection of items',
        '      post:',
        '       description: <<foo>><<foo>><<foo>> fixed text <<bar>><<bar>><<bar>>',
        '/:',
        '  type: { collection: { foo: bar, bar: foo} }'
        """

        expected = %{"title" => "Test",
                     "resourceTypes" => [%{"collection" => %{"displayName" => "Collection",
                                                             "description" => "<<foo>> resourceType should be used for any collection of items",
                                                             "post" => %{"description" => "<<foo>><<foo>><<foo>> fixed text <<bar>><<bar>><<bar>>"}
                                                            }
                                          }],
                     "resources" => [%{"description" => "bar resourceType should be used for any collection of items",
                                       "type" => %{"collection" => %{"foo" => "bar",
                                                                     "bar" => "foo"
                                                                    }},
                                       "relativeUri" => "/",
                                       "relativeUriPathSegments" => [],
                                       "methods" => [%{"method" => "post",
                                                       "description" => "barbarbar fixed text foofoofoo"
                                                      }] 
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if parameters are missing" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection',
        '      description: <<foo>> resourceType should be used for any collection of items',
        '      post:',
        '       description: <<foo>><<foo>><<foo>> fixed text <<bar>><<bar>><<bar>>',
        '       <<foo>>: <<bar>>',
        '/:',
        '  type: { collection: { foo: bar } }'
        """

        assert_raise(RamlParseError, ~r(value was not provided for parameter: bar), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if resourceType uses a missing trait" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - secured:',
        '      displayName: OAuth 2.0 security',
        '      queryParameters:',
        '       access_token:',
        '         description: OAuth Access token',
        'resourceTypes:',
        '  - collection:',
        '      is: [ blah ]',
        '      displayName: Collection',
        '      description: This resourceType should be used for any collection of items',
        '      post:',
        '       foo:',
        '/:',
        '  type: collection'
        """
        assert_raise(RamlParseError, ~r(there is no trait named blah), fn ->
          parse_string!(str)
        end)
      end

      it "should apply a trait to a resource type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - secured:',
        '      displayName: OAuth 2.0 security',
        '      queryParameters:',
        '       access_token:',
        '         description: OAuth Access token',
        'resourceTypes:',
        '  - collection:',
        '      is: [ secured ]',
        '      displayName: Collection',
        '      description: This resourceType should be used for any collection of items',
        '      post:',
        '       body:',
        '/:',
        '  type: collection'
        """

        expected = %{"title" => "Test",
                     "traits" => [%{"secured" => %{"displayName" => "OAuth 2.0 security",
                                                   "queryParameters" => %{"access_token" => %{"description" => "OAuth Access token",
                                                                                              "displayName" => "access_token",
                                                                                              "type" => "string"
                                                                                             }}
                                                  }}
                                 ],
                     "resourceTypes" => [%{"collection" => %{"is" => ["secured"],
                                                             "displayName" => "Collection",
                                                             "description" => "This resourceType should be used for any collection of items",
                                                             "post" => %{"body" => nil}
                                                            }
                                          }],
                     "resources" => [%{"description" => "This resourceType should be used for any collection of items",
                                       "type" => "collection",
                                       "relativeUri" => "/",
                                       "relativeUriPathSegments" => [],
                                       "methods" => [%{"queryParameters" => %{"access_token" => %{"description" => "OAuth Access token",
                                                                                                  "displayName" => "access_token",
                                                                                                  "type" => "string"
                                                                                                 }},
                                                       "body" => nil,
                                                       "method" => "post"
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should apply a resource type skipping missing optional parameter" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection',
        '      description: This resourceType should be used for any collection of items',
        '      post:',
        '       body:',
        '      "get?":',
        '       body:',
        '/:',
        '  type: collection'
        """

        expected = %{"title" => "Test",
                     "resourceTypes" => [%{"collection" => %{"displayName" => "Collection",
                                                             "description" => "This resourceType should be used for any collection of items",
                                                             "post" => %{"body" => nil},
                                                             "get?" => %{"body" => nil}
                                                            }}],
                     "resources" => [%{"description" => "This resourceType should be used for any collection of items",
                                       "type" => "collection",
                                       "relativeUriPathSegments" => [],
                                       "relativeUri" => "/",
                                       "methods" => [%{"method" => "post",
                                                       "body" => nil
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should apply a resource type adding optional parameter" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'resourceTypes:',
        '  - collection:',
        '      displayName: Collection',
        '      description: This resourceType should be used for any collection of items',
        '      post?:',
        '       description: Some description',
        '/:',
        '  type: collection',
        '  post: {}'
        """

        expected = %{"title" => "Test",
                     "resourceTypes" => [%{"collection" => %{"displayName" => "Collection",
                                                             "description" => "This resourceType should be used for any collection of items",
                                                             "post?" => %{"description" => "Some description"}
                                                            }}],
                     "resources" => [%{"description" => "This resourceType should be used for any collection of items",
                                       "type" => "collection",
                                       "relativeUriPathSegments" => [],
                                       "relativeUri" => "/",
                                       "methods" => [%{"method" => "post",
                                                       "description" => "Some description"
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end
    end

    describe "Parameter methods" do
      describe '- Unknown methods' do
        describe '- In resources' do
          it "should fail if calling an unknown method in a property" do
            str = """
            '#%RAML 0.8',
            '---',
            'title: Test',
            'resourceTypes:',
            '  - collection:',
            '      displayName: Collection',
            '      <<parameterName|sarasa>>: resourceType should be used for any collection of items',
            '/:'
            """
            assert_raise(RamlParseError, ~r(unknown function applied to property name), fn ->
              parse_string!(str)
            end)
          end

          it "should fail if calling an unknown method in a value in an applied type" do
            str = """
            '#%RAML 0.8',
            '---',
            'title: Test',
            'resourceTypes:',
            '  - collection:',
            '      displayName: Collection',
            '      description: <<parameterName|unknownword>> resourceType should be used for any collection of items',
            '/:',
            '  type: { collection: {parameterName: someValue} }'
            """
            assert_raise(RamlParseError, ~r(unknown function applied to parameter), fn ->
              parse_string!(str)
            end)
          end


        end

        describe '- In traits' do
          it "should fail if calling an unknown method in a property" do
            str = """
            '#%RAML 0.8',
            '---',
            'title: Test',
            'traits:',
            '  - traitName:',
            '      displayName: Collection',
            '      <<parameterName|sarasa>>: resourceType should be used for any collection of items',
            '/:'
            """
            assert_raise(RamlParseError, ~r(unknown function applied to property name), fn ->
              parse_string!(str)
            end)
          end

          it "should fail if calling an unknown method in a value in an applied trait" do
            str = """
            '#%RAML 0.8',
            '---',
            'title: Test',
            'traits:',
            '  - traitName:',
            '      displayName: Collection',
            '      description: <<parameterName|unknownword>> resourceType should be used for any collection of items',
            '/:',
            '  is: [ traitName: {parameterName: someValue} ]',
            '  get:'
            """
            assert_raise(RamlParseError, ~r(unknown function applied to parameter), fn ->
              parse_string!(str)
            end)
          end




        end
      end

      describe '- Singuralize' do
        describe '- In resources' do
          it "should fail if calling an unknown method in a value in an applied type" do
            str = """
            '#%RAML 0.8',
            '---',
            'title: Test',
            'resourceTypes:',
            '  - collection:',
            '      displayName: Collection',
            '      description: <<parameterName|!singularize>> resourceType should be used for any collection of items',
            '/:',
            '  type: { collection: {parameterName: commuters} }'
            """
            expected = %{"title" => "Test",
                         "resourceTypes" => [%{"collection" => %{"displayName" => "Collection",
                                                                 "description" => "<<parameterName|!singularize>> resourceType should be used for any collection of items"
                                                                }}],
                         "resources" => [%{"description" => "commuter resourceType should be used for any collection of items",
                                           "type" => %{"collection" => %{"parameterName" => "commuters"}},
                                           "relativeUri" => "/",
                                           "relativeUriPathSegments" => [],
                                          }]
                        }
            {:ok, result} = parse_string(str)
            assert result == expected
          end
        end

        describe '- In traits' do
          it "should fail if calling an unknown method in a value in an applied trait" do
            str = """
            '#%RAML 0.8',
            '---',
            'title: Test',
            'traits:',
            '  - traitName:',
            '      displayName: Collection',
            '      description: <<parameterName|!singularize>> resourceType should be used for any collection of items',
            '/:',
            '  is: [ traitName: {parameterName: commuters} ]',
            '  get:'
            """
            expected = %{"title" => "Test",
                         "traits" => [%{"traitName" => %{"displayName" => "Collection",
                                                         "description" => "<<parameterName|!singularize>> resourceType should be used for any collection of items"
                                                        }}],
                         "resources" => [%{"is" => [%{"traitName" => %{"parameterName" => "commuters"}}],
                                           "relativeUri" => "/",
                                           "relativeUriPathSegments" => [],
                                           "methods" => [%{"description" => "commuter resourceType should be used for any collection of items",
                                                           "method" => "get"
                                                          }]
                                          }]
                        }
            {:ok, result} = parse_string(str)
            assert result == expected
          end
        end
      end

      describe "Pluralize" do
        describe '- In resources' do
          it "should fail if calling an unknown method in a value in an applied type" do
            str = """
            '#%RAML 0.8',
            '---',
            'title: Test',
            'resourceTypes:',
            '  - collection:',
            '      displayName: Collection',
            '      description: <<parameterName|!pluralize>> resourceType should be used for any collection of items',
            '/:',
            '  type: { collection: {parameterName: commuter} }'
            """
            expected = %{"title" => "Test",
                         "resourceTypes" => [%{"collection" => %{"displayName" => "Collection",
                                                                 "description" => "<<parameterName|!pluralize>> resourceType should be used for any collection of items"
                                                                }}],
                         "resources" => [%{"description" => "commuters resourceType should be used for any collection of items",
                                           "type" => %{"collection" => %{"parameterName" => "commuter"}},
                                           "relativeUri" => "/",
                                           "relativeUriPathSegments" => []
                                          }]
                        }
            {:ok, result} = parse_string(str)
            assert result == expected
          end
        end

        describe '- In traits' do
          it "should fail if calling an unknown method in a value in an applied trait" do
            str = """
            '#%RAML 0.8',
            '---',
            'title: Test',
            'traits:',
            '  - traitName:',
            '      displayName: Collection',
            '      description: <<parameterName|!pluralize>> resourceType should be used for any collection of items',
            '/:',
            '  is: [ traitName: {parameterName: commuter} ]',
            '  get:'
            """
            expected = %{"title" => "Test",
                             "traits" => [%{"traitName" => %{"displayName" => "Collection",
                                                             "description" => "<<parameterName|!pluralize>> resourceType should be used for any collection of items"
                                                            }}],
                             "resources" => [%{"is" => [%{"traitName" => %{"parameterName" => "commuter"}}],
                                               "relativeUri" => "/",
                                               "methods" => [%{"description" => "commuters resourceType should be used for any collection of items",
                                                               "method" => "get"
                                                              }],
                                               "relativeUriPathSegments" => [],
                                              }]
                            }
            {:ok, result} = parse_string(str)
            assert result == expected
          end
        end
      end
    end

    describe "Schema support" do
      it "should not fail when specifying schemas at the root level" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'schemas:',
        '  - foo: |',
        '       Blah blah',
        '/resource:'
        """

        expected = %{"title" => "Test",
                     "schemas" => [%{"foo" => "Blah blah\n"}],
                     "resources" => [%{"relativeUri" => "/resource",
                                       "relativeUriPathSegments" => ["resource"],
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail when specifying schemas is scalar" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'schemas: foo',
        '/:'
        """
        assert_raise(RamlParseError, ~r(schemas property must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when specifying schemas is scalar" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'schemas: {}',
        '/:'
        """
        assert_raise(RamlParseError, ~r(schemas property must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when schema is null" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'schemas:',
        '  - foo:',
        '/:'
        """
        assert_raise(RamlParseError, ~r(schema foo must be a string), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when schema is an array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'schemas:',
        '  - foo: []',
        '/:'
        """
        assert_raise(RamlParseError, ~r(schema foo must be a string), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if a schema is a map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'schemas:',
        '  - foo: |',
        '       Blah blah',
        '/foo:',
        '  displayName: A',
        '  post:' ,
        '    description: Blah',
        '    body:',
        '      application/json:',
        '        schema: foo3',
        '    responses:',
        '      200:',
        '       body:',
        '        application/json:',
        '          schema: foo',
        '      201:',
        '       body:',
        '        application/json:',
        '          schema: {}'
        """
        assert_raise(RamlParseError, ~r(schema must be a string), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if a schema is an array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'schemas:',
        '  - foo: |',
        '       Blah blah',
        '/foo:',
        '  displayName: A',
        '  post:' ,
        '    description: Blah',
        '    body:',
        '      application/json:',
        '        schema: foo3',
        '    responses:',
        '      200:',
        '       body:',
        '        application/json:',
        '          schema: foo',
        '      201:',
        '       body:',
        '        application/json:',
        '          schema: []'
        """
        assert_raise(RamlParseError, ~r(schema must be a string), fn ->
          parse_string!(str)
        end)
      end

      it "should apply trait" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'schemas:',
        '  - foo: |',
        '       Blah blah',
        '    faa: |',
        '       Blah blah',
        '/foo:',
        '  displayName: A',
        '  post:' ,
        '    description: Blah',
        '    body:',
        '      application/json:',
        '        schema: foo3',
        '    responses:',
        '      200:',
        '        body:',
        '          application/json:',
        '            schema: foo',
        '      201:',
        '        body:',
        '          application/json:',
        '            schema: foo2'
        """

        expected = %{"title" => 'Test',
                     "schemas" => [%{"foo" => "Blah blah\n",
                                     "faa" => "Blah blah\n"
                                    }],
                     "resources" => [%{"displayName" => 'A',
                                       "relativeUri" => '/foo',
                                       "relativeUriPathSegments" => ["foo"],
                                       "methods" => [%{"description" => 'Blah',
                                                       "body" => %{"application/json" => %{"schema" => "foo3"}},
                                                       "responses" => %{"200" => %{"body" => %{"application/json" => %{"schema" => "Blah blah\n"}}},
                                                                        "201" => %{"body" => %{"application/json" => %{"schema" => "foo2"}}}
                                                                       },
                                                       "method" => 'post'
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should apply trait multiple times" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'schemas:',
        '  - foo: |',
        '       Blah blah',
        '/foo:',
        '  displayName: A',
        '  post:' ,
        '    description: Blah',
        '    body:',
        '      application/json:',
        '        schema: foo',
        '    responses:',
        '      200:',
        '        body:',
        '         application/json:',
        '           schema: foo',
        '      201:',
        '        body:',
        '         application/json:',
        '           schema: foo2'
        """

        expected = %{"title" => 'Test',
                     "schemas" => [%{"foo" => "Blah blah\n"}],
                     "resources" => [%{"displayName" => 'A',
                                       "relativeUri" => '/foo',
                                       "relativeUriPathSegments" => ["foo"],
                                       "methods" => [%{"description" => 'Blah',
                                                       "body" => %{"application/json" => %{"schema" => "Blah blah\n"}},
                                                       "responses" => %{"200" => %{"body" => %{"application/json" => %{"schema" => "Blah blah\n"}}},
                                                                        "201" => %{"body" => %{"application/json" => %{"schema" => "foo2"}}}
                                                                       },
                                                       "method" => 'post'
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should apply multiple schemas" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'schemas:',
        '  - foo: |',
        '       Blah blah',
        '  - foo2: |',
        '       halb halB',
        '/foo:',
        '  displayName: A',
        '  post:' ,
        '    description: Blah',
        '    body:',
        '      application/json:',
        '        schema: foo',
        '    responses:',
        '      200:',
        '        body:',
        '         application/json:',
        '          schema: foo',
        '      201:',
        '        body:',
        '         application/json:',
        '          schema: foo2',
        ''
        """

        expected = %{"title" => 'Test',
                     "schemas" => [%{"foo" => "Blah blah\n"},
                                   %{"foo2" => "halb halB\n"}
                                  ],
                     "resources" => [%{"displayName" => 'A',
                                       "relativeUriPathSegments" => ["foo"],
                                       "relativeUri" => '/foo',
                                       "methods" => [%{"description" => 'Blah',
                                                       "body" => %{"application/json" => %{"schema" => "Blah blah\n"}},
                                                       "responses" => %{"200" => %{"body" => %{"application/json" => %{"schema" => "Blah blah\n"}}},
                                                                        "201" => %{"body" => %{"application/json" => %{"schema" => "halb halB\n"}}}
                                                                       },
                                                       "method" => 'post'
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end
    end

    describe "Security schemes" do
      it "should fail when schemes is map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        '  foo: |',
        '       Blah blah',
        '/resource:'
        """
        assert_raise(RamlParseError, ~r(invalid security schemes property, it must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when schemes is scalar" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes: foo',
        '/resource:'
        """
        assert_raise(RamlParseError, ~r(invalid security schemes property, it must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when schemes is null" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        '/resource:'
        """
        assert_raise(RamlParseError, ~r(invalid security schemes property, it must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed when schemes is empty" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes: []',
        '/resource:'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [],
                     "resources" => [%{"relativeUri" => "/resource",
                                       "relativeUriPathSegments" => ["resource"]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail when schemes has a null scheme" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - ',
        '/resource:'
        """
        assert_raise(RamlParseError, ~r(invalid security scheme property, it must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when scheme is scalar" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme: scalar',
        '/resource:'
        """
        assert_raise(RamlParseError, ~r(invalid security scheme property, it must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when scheme is array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme: []',
        '/resource:'
        """
        assert_raise(RamlParseError, ~r(invalid security scheme property, it must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when scheme contains a wrong property" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     property: null',
        '/resource:'
        """
        assert_raise(RamlParseError, ~r(property: 'property' is invalid in a security scheme), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when scheme does not have type" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '/resource:'
        """
        assert_raise(RamlParseError, ~r(schemes type must be any of: "OAuth 1.0", "OAuth 2.0", "Basic Authentication", "Digest Authentication", "x-{.+}"), fn ->
          parse_string!(str)
        end)
      end

      it 'should succeed when type is "OAuth 2.0"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type: OAuth 2.0',
        '     settings:',
        '       authorizationUri: https://www.dropbox.com/1/oauth2/authorize',
        '       accessTokenUri: https://api.dropbox.com/1/oauth2/token',
        '       authorizationGrants: [ code, token ]',
        '/resource:'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme" => %{"description" => "This is some text",
                                                           "type" => "OAuth 2.0",
                                                           "settings" => %{"authorizationUri" => "https://www.dropbox.com/1/oauth2/authorize",
                                                                           "accessTokenUri" => "https://api.dropbox.com/1/oauth2/token",
                                                                           "authorizationGrants" => ["code", "token"]
                                                                          }
                                                          }}],
                     "resources" => [%{"relativeUri" => "/resource",
                                       "relativeUriPathSegments" => ["resource"]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it 'should succeed when type is "OAuth 1.0"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type: OAuth 1.0',
        '     settings:',
        '       requestTokenUri: https://api.dropbox.com/1/oauth/request_token',
        '       authorizationUri: https://www.dropbox.com/1/oauth/authorize',
        '       tokenCredentialsUri: https://api.dropbox.com/1/oauth/access_token',
        '/resource:'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme" => %{"description" => "This is some text",
                                                           "type" => "OAuth 1.0",
                                                           "settings" => %{"requestTokenUri" => "https://api.dropbox.com/1/oauth/request_token",
                                                                          "authorizationUri" => "https://www.dropbox.com/1/oauth/authorize",
                                                                          "tokenCredentialsUri" => "https://api.dropbox.com/1/oauth/access_token"
                                                                         }
                                                          }}],
                     "resources" => [%{"relativeUri" => "/resource",
                                       "relativeUriPathSegments" => ["resource"]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it 'should succeed when type is "Basic Authentication"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type: Basic Authentication',
        '/resource:'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme" => %{"description" => "This is some text",
                                                           "type" => "Basic Authentication"
                                                          }}],
                     "resources" => [%{"relativeUri" => "/resource",
                                       "relativeUriPathSegments" => ["resource"]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it 'should succeed when type is "Digest Authentication"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type: Digest Authentication',
        '/resource:'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme" => %{"description" => "This is some text",
                                                           "type" => "Digest Authentication"
                                                          }}],
                     "resources" => [%{"relativeUriPathSegments" => ["resource"],
                                       "relativeUri" => "/resource"
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it 'should succeed when type is "x-other-something"' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type: x-other-something',
        '/resource:'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme" => %{"description" => "This is some text",
                                                           "type" => "x-other-something"
                                                          }}],
                     "resources" => [%{"relativeUriPathSegments" => ["resource"],
                                       "relativeUri" => "/resource"
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed when using null securityScheme" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type: x-other-something',
        'securedBy: [ null ]',
        '/resource:'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme" => %{"description" => "This is some text",
                                                           "type" => "x-other-something"
                                                          }}],
                     "securedBy" => [nil],
                     "resources" => [%{"relativeUriPathSegments" => ["resource"],
                                       "relativeUri" => "/resource"
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed when using a securityScheme" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type: x-other-something',
        'securedBy: [ scheme ]',
        '/resource:'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme" => %{"description" => "This is some text",
                                                           "type" => "x-other-something"
                                                          }}],
          "securedBy" => ["scheme"],
          "resources" => [%{"relativeUriPathSegments" => ["resource"],
                            "relativeUri" => "/resource"
                           }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed when using a securityScheme" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type: x-other-something',
        '/resource:',
        '  securedBy: [ scheme ]'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme" => %{"description" => "This is some text",
                                                           "type" => "x-other-something"
                                                          }}],
                     "resources" => [%{"securedBy" => ["scheme"],
                                       "relativeUriPathSegments" => ["resource"],
                                       "relativeUri" => "/resource"
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed when using a securityScheme" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type: x-other-something',
        '/resource:',
        '  get:',
        '    securedBy: [ scheme ]'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme" => %{"description" => "This is some text",
                                                           "type" => "x-other-something"
                                                          }}],
                     "resources" => [%{"relativeUri" => "/resource",
                                       "relativeUriPathSegments" => ["resource"],
                                       "methods" => [%{"method" => "get",
                                                       "securedBy" => ["scheme"]
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail when using a securityScheme twice in the same property" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type: x-other-something',
        '/resource:',
        '  get:',
        '    securedBy: [ scheme, scheme ]'
        """
        assert_raise(RamlParseError, ~r(securitySchemes can only be referenced once in a securedBy property), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when type is null" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type:',
        '/resource:'
        """
        assert_raise(RamlParseError, ~r(schemes type must be any of: "OAuth 1.0", "OAuth 2.0", "Basic Authentication", "Digest Authentication", "x-{.+}"), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when type is array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type: []',
        '/resource:'
        """
        assert_raise(RamlParseError, ~r(schemes type must be any of: "OAuth 1.0", "OAuth 2.0", "Basic Authentication", "Digest Authentication", "x-{.+}"), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when type is map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        ' - scheme:',
        '     description: This is some text',
        '     type: {}',
        '/resource:'
        """
        assert_raise(RamlParseError, ~r(schemes type must be any of: "OAuth 1.0", "OAuth 2.0", "Basic Authentication", "Digest Authentication", "x-{.+}"), fn ->
          parse_string!(str)
        end)
      end

      it "resource should inherit securedBy from root" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        '  - scheme1:',
        '      type: x-other',
        '      description: some thing goes here',
        'securedBy: [scheme1]',
        '/someResource:',
        '  get:',
        '  description: aslkjdhakjfh'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme1" => %{"type" => "x-other",
                                                            "description" => "some thing goes here"
                                                           }}],
                     "securedBy" => ["scheme1"],
                     "resources" => [%{"description" => "aslkjdhakjfh",
                                       "relativeUri" => "/someResource",
                                       "methods" => [%{"securedBy" => ["scheme1"],
                                                       "method" => "get"
                                                      }],
                                       "relativeUriPathSegments" => ["someResource"]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "method should inherit securedBy from resource" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        '  - scheme1:',
        '      type: x-other',
        '      description: some thing goes here',
        '/someResource:',
        '  securedBy: [scheme1]',
        '  get:',
        '  description: aslkjdhakjfh'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme1" => %{"type" => "x-other",
                                                            "description" => "some thing goes here"
                                                           }}],
                     "resources" => [%{"securedBy" => ["scheme1"],
                                       "description" => "aslkjdhakjfh",
                                       "relativeUri" => "/someResource",
                                       "methods" => [%{"securedBy" => ["scheme1"],
                                                       "method" => "get"
                                                      }],
                                       "relativeUriPathSegments" => ["someResource"]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "method should not inherit securedBy from resource if it has property" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        '  - scheme1:',
        '      type: x-other',
        '      description: some thing goes here',
        '  - scheme2:',
        '      type: x-other',
        '      description: some thing goes here',
        '/someResource:',
        '  securedBy: [scheme2]',
        '  get:',
        '    securedBy: [scheme1]',
        '  description: aslkjdhakjfh'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme1" => %{"type" => "x-other",
                                                            "description" => "some thing goes here"
                                                           }},
                                           %{"scheme2" => %{"type" => "x-other",
                                                            "description" => "some thing goes here"
                                                           }}
                                          ],
                     "resources" => [%{"securedBy" => ["scheme2"],
                                       "description" => "aslkjdhakjfh",
                                       "relativeUri" => "/someResource",
                                       "methods" => [%{"securedBy" => ["scheme1"],
                                                       "method" => "get"
                                                      }],
                                       "relativeUriPathSegments" => ["someResource"]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "method should not inherit securedBy from root if it has property" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'securitySchemes:',
        '  - scheme1:',
        '      type: x-other',
        '      description: some thing goes here',
        '  - scheme2:',
        '      type: x-other',
        '      description: some thing goes here',
        'securedBy: [scheme2]',
        '/someResource:',
        '  get:',
        '    securedBy: [scheme1]',
        '  description: aslkjdhakjfh'
        """
        expected = %{"title" => "Test",
                     "securitySchemes" => [%{"scheme1" => %{"type" => "x-other",
                                                            "description" => "some thing goes here"
                                                           }},
                                           %{"scheme2" => %{"type" => "x-other",
                                                            "description" => "some thing goes here"
                                                           }}
                                          ],
                     "securedBy" => ["scheme2"],
                     "resources" => [%{"description" => "aslkjdhakjfh",
                                       "relativeUri" => "/someResource",
                                       "methods" => [%{"securedBy" => ["scheme1"],
                                                       "method" => "get"
                                                      }],
                                       "relativeUriPathSegments" => ["someResource"]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end
    end

    describe "Resource Validations" do
      it "should fail if using parametric property name in a resource" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  get:',
        '  /b:',
        '    displayName: AB',
        '    <<property>>:'
        """
        assert_raise(RamlParseError, ~r(property '<<property>>' is invalid in a resource), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if displayName is map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  get:',
        '  /b:',
        '    displayName: {}'
        """
        assert_raise(RamlParseError, ~r(property 'displayName' must be a string), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if displayName is an array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  get:',
        '  /b:',
        '    displayName: []'
        """
        assert_raise(RamlParseError, ~r(property 'displayName' must be a string), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if description is map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  get:',
        '  /b:',
        '    description: {}'
        """
        assert_raise(RamlParseError, ~r(property 'description' must be a string), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if description is an array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  get:',
        '  /b:',
        '    description: []'
        """
        assert_raise(RamlParseError, ~r(property 'description' must be a string), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if method is an array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  get: []'
        """
        assert_raise(RamlParseError, ~r(method must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if method is scalar" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  get: false'
        """
        assert_raise(RamlParseError, ~r(method must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should show displayName in a method" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  get:',
        '    displayName: SomeName'
        """

        expected = %{"title" => "Test",
                     "resources" => [%{"displayName" => "A",
                                       "relativeUri" => "/a",
                                       "methods" => [%{"displayName" => "SomeName",
                                                       "method" => "get"
                                                      }],
                                       "relativeUriPathSegments" => ["a"]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if methods description is map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  get:',
        '    description: {}'
        """
        assert_raise(RamlParseError, ~r(property 'description' must be a string), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if methods description is an array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/a:',
        '  displayName: A',
        '  get:',
        '    description: []'
        """
        assert_raise(RamlParseError, ~r(property 'description' must be a string), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when declaring a URI parameter in a resource with a wrong property" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '/{hello}:',
        '  uriParameters:',
        '    hello:',
        '      displayName: A',
        '      blah: This is A'
        """

        assert_raise(RamlParseError, ~r(unknown property blah), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when declaring a URI parameter in a nested resource with a wrong property" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '/{hello}:',
        '  uriParameters:',
        '    hello:',
        '      displayName: A',
        '  /{hello}:',
        '    uriParameters:',
        '      hello:',
        '        displayName: A',
        '        blah: This is A'
        """

        assert_raise(RamlParseError, ~r(unknown property blah), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when not using a declared URI parameter in a nested resource" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '/{hello}:',
        '  uriParameters:',
        '    hello:',
        '      displayName: A',
        '  /{hello}:',
        '    uriParameters:',
        '      not-used:',
        '        displayName: A'
        """

        assert_raise(RamlParseError, ~r(not-used uri parameter unused), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if headers is string" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        'baseUriParameters:',
        '  a:',
        '    displayName: A',
        '    description: This is A',
        '/{hello}:',
        '  get:',
        '    headers: foo'
        """

        assert_raise(RamlParseError, ~r(property: 'headers' must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if headers is array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/foo:',
        '  get:',
        '    headers: []'
        """

        assert_raise(RamlParseError, ~r(property: 'headers' must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed if headers is null" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    headers:'
        """

        expected = %{"title" => "Test",
                     "resources" => [%{"relativeUriPathSegments" => ["foo"],
                                       "relativeUri" => "/foo",
                                       "methods" => [%{"headers" => nil,
                                                       "method" => "get"
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if header is scalar" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    headers:',
        '      foo: bar'
        """
        assert_raise(RamlParseError, ~r(each header must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if header is empty an array" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    headers:',
        '      foo: []'
        """
        assert_raise(RamlParseError, ~r(named parameter needs at least one type), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if header uses unknown property" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    headers:',
        '      TemplateHeader:',
        '       foo:'
        """
        assert_raise(RamlParseError, ~r(unknown property foo), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if queryParams is string" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        '/{hello}:',
        '  get:',
        '    queryParameters: foo'
        """

        assert_raise(RamlParseError, ~r(property: 'queryParameters' must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if queryParameters is array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/foo:',
        '  get:',
        '    queryParameters: []'
        """

        assert_raise(RamlParseError, ~r(property: 'queryParameters' must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed if queryParameters is null" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    queryParameters:'
        """

        expected = %{"title" => "Test",
                     "resources" => [%{"relativeUri" => "/foo",
                                       "relativeUriPathSegments" => ["foo"],
                                       "methods" => [%{"queryParameters" => nil,
                                                       "method" => "get"
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if queryParameters use wrong property name" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    queryParameters:',
        '     FooParam:',
        '       bar: bar'
        """
        assert_raise(RamlParseError, ~r(unknown property bar), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if body is a scalar" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    body: foo'
        """
        assert_raise(RamlParseError, ~r(property: body specification must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed if body is null" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    body:'
        """
        expected = %{"title" => "Test",
                     "resources" => [%{"relativeUriPathSegments" => ["foo"],
                                       "relativeUri" => "/foo",
                                       "methods" => [%{"body" => nil,
                                                       "method" => "get"
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if body is using implicit after explicit body" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    body:',
        '      application/json:',
        '      schema: foo'
        """
        assert_raise(RamlParseError, ~r(not compatible with explicit Media Type), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if body is using explicit after implicit body" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    body:',
        '      schema: foo',
        '      application/json:'
        """
        assert_raise(RamlParseError, ~r(not compatible with implicit default Media Type), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if formParameters kicks implicit mode on" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    body:',
        '      formParameters:',
        '      application/json:'
        """
        assert_raise(RamlParseError, ~r(not compatible with implicit default Media Type), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if schema kicks implicit mode on" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    body:',
        '      schema: foo',
        '      application/json:'
        """
        assert_raise(RamlParseError, ~r(not compatible with implicit default Media Type), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if example kicks implicit mode on" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/foo:',
        '  get:',
        '    body:',
        '      example: foo',
        '      application/json:'
        """
        assert_raise(RamlParseError, ~r(not compatible with implicit default Media Type), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if formParameters is string" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        '/{hello}:',
        '  post:',
        '    body:',
        '      formParameters: foo'
        """

        assert_raise(RamlParseError, ~r(property: 'formParameters' must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if queryParameters is array" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        '/{hello}:',
        '  post:',
        '    body:',
        '      formParameters: []'
        """

        assert_raise(RamlParseError, ~r(property: 'formParameters' must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed if queryParameters is null" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        'mediaType: application/json',
        'baseUri: http://{a}.myapi.org',
        '/{hello}:',
        '  post:',
        '    body:',
        '      formParameters:'
        """

        expected = %{"title" => "Test",
                     "mediaType" => "application/json",
                     "baseUri" => "http://{a}.myapi.org",
                     "protocols" => ['HTTP'],
                     "resources" => [%{"relativeUriPathSegments" => ["{hello}"],
                                       "relativeUri" => "/{hello}",
                                       "methods" => [%{"body" => %{"application/json" => %{"formParameters" => nil}},
                                                       "method" => "post",
                                                       "protocols" => ['HTTP'],
                                                      }],
                                       "uriParameters" => %{"hello" => %{"type" => "string",
                                                                         "required" => true,
                                                                         "displayName" => "hello"
                                                                        }}
                                      }],
                     "baseUriParameters" => %{"a" => %{"type" => "string",
                                                       "required" => true,
                                                       "displayName" => "a"
                                                      }}
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if queryParameters use wrong property name" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        'baseUri: http://{a}.myapi.org',
        '/{hello}:',
        '  post:',
        '    body:',
        '      formParameters:',
        '        Formparam:',
        '           foo: blah'
        """
        assert_raise(RamlParseError, ~r(unknown property foo), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if responses is scalar" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/root:',
        '  post:',
        '    responses: scalar'
        """
        assert_raise(RamlParseError, ~r(property: 'responses' must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if responses is array" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/root:',
        '  post:',
        '    responses: [ value ]'
        """
        assert_raise(RamlParseError, ~r(property: 'responses' must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed if responses is null" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/root:',
        '  post:',
        '    responses:'
        """
        expected = %{"title" => "Test",
                     "resources" => [%{"relativeUriPathSegments" => ["root"],
                                       "relativeUri" => "/root",
                                       "methods" => [%{"responses" => nil,
                                                       "method" => "post"
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if response code is string" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/root:',
        '  post:',
        '    responses:',
        '     responses:'
        """
        assert_raise(RamlParseError, ~r(each response key must be an integer), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if response code is null" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/root:',
        '  post:',
        '    responses:',
        '     ~:'
        """
        assert_raise(RamlParseError, ~r(each response key must be an integer), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if response code in list is null" do
        str = """
        '#%RAML 0.8',
        'title: Test',
        '/root:',
        '  post:',
        '    responses:',
        '     [string]:'
        """
        assert_raise(RamlParseError, ~r(only scalar map keys are allowed in RAML), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "Base Uri Parameters" do
      it "should fail when a resource specified baseUriParams and baseuri is null" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        '/resource:',
        '  baseUriParameters:',
        '   domainName:',
        '     example: your-bucket'
        """
        assert_raise(RamlParseError, ~r(base uri parameters defined when there is no baseUri), fn ->
          parse_string!(str)
        end)
      end

      it "should fail when a resource specified baseUriParams unused in the URI" do
        str = """
        '#%RAML 0.8',
        '---',
        'baseUri: https://myapi.com',
        'title: Test',
        '/resource:',
        '  baseUriParameters:',
        '   domainName:',
        '     example: your-bucket'
        """
        assert_raise(RamlParseError, ~r(domainName uri parameter unused), fn ->
          parse_string!(str)
        end)
      end

      it "should succeed when a overriding baseUriParams in a resource" do
        str = """
        '#%RAML 0.8',
        '---',
        'baseUri: https://{domainName}.myapi.com',
        'title: Test',
        '/resource:',
        '  baseUriParameters:',
        '   domainName:',
        '     example: your-bucket'
        """
        expected = %{"baseUri" => "https://{domainName}.myapi.com",
                     "protocols" => ['HTTPS'],
                     "title" => "Test",
                     "baseUriParameters" => %{"domainName" => %{"type" => "string",
                                                                "required" => true,
                                                                "displayName" => "domainName"
                                                               }},
                     "resources" => [%{"baseUriParameters" => %{"domainName" => %{"example" => "your-bucket",
                                                                                  "type" => "string",
                                                                                  "required" => true,
                                                                                  "displayName" => "domainName"
                                                                                 }},
                                       "relativeUri" => "/resource",
                                       "relativeUriPathSegments" => ["resource"]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed when a overriding baseUriParams in a method" do
        str = """
        '#%RAML 0.8',
        '---',
        'baseUri: https://{domainName}.myapi.com',
        'title: Test',
        '/resource:',
        '  get:',
        '     baseUriParameters:',
        '       domainName:',
        '         example: your-bucket'
        """
        expected = %{"baseUri" => "https://{domainName}.myapi.com",
                     "protocols" => ['HTTPS'],
                     "title" => "Test",
                     "resources" => [%{"relativeUriPathSegments" => ["resource"],
                                       "relativeUri" => "/resource",
                                       "methods" => [%{"baseUriParameters" => %{"domainName" => %{"example" => "your-bucket",
                                                                                                  "type" => "string",
                                                                                                  "required" => true,
                                                                                                  "displayName" => "domainName"
                                                                                                 }},
                                                       "method" => "get",
                                                       "protocols" => ['HTTPS'],
                                                      }],
                                      }],
                     "baseUriParameters" => %{"domainName" => %{"type" => "string",
                                                                "required" => true,
                                                                "displayName" => "domainName"
                                                               }}
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should succeed when a overriding baseUriParams in a resource 3 levels deep" do
        str = """
        '#%RAML 0.8',
        '---',
        'baseUri: https://{domainName}.myapi.com',
        'title: Test',
        '/resource:',
        ' /resource:',
        '   /resource:',
        '     baseUriParameters:',
        '       domainName:',
        '         example: your-bucket'
        """
        expected = %{"baseUri" => "https://{domainName}.myapi.com",
                     "protocols" => ['HTTPS'],
                     "title" => "Test",
                     "baseUriParameters" => %{"domainName" => %{"type" => "string",
                                                                "required" => true,
                                                                "displayName" => "domainName"
                                                               }},
                     "resources" => [%{"relativeUriPathSegments" => ["resource"],
                                       "relativeUri" => "/resource",
                                       "resources" => [%{"relativeUriPathSegments" => ["resource"],
                                                         "relativeUri" => "/resource",
                                                         "resources" => [%{"baseUriParameters" => %{"domainName" => %{"example" => "your-bucket",
                                                                                                                      "type" => "string",
                                                                                                                      "required" => true,
                                                                                                                      "displayName" => "domainName"
                                                                                                                     }},
                                                                           "relativeUri" => "/resource",
                                                                           "relativeUriPathSegments" => ["resource"],
                                                                          }]
                                                        }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end
    end

    describe "Documentation section" do
      it "should fail if docsection is empty array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'documentation: []'
        """

        assert_raise(RamlParseError, ~r(there must be at least one document in the documentation section), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if docsection is missing title" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'documentation:',
        '  - content: Content'
        """

        assert_raise(RamlParseError, ~r(a documentation entry must have title property), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if docsection is missing content" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'documentation:',
        '  - title: Getting Started'
        """

        assert_raise(RamlParseError, ~r(a documentation entry must have content property), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if docsection is map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'documentation: {}'
        """

        assert_raise(RamlParseError, ~r(documentation must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if docsection is scalar" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'documentation: scalar'
        """

        assert_raise(RamlParseError, ~r(documentation must be an array), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if docentry is scalar" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'documentation: [scalar]'
        """

        assert_raise(RamlParseError, ~r(each documentation section must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if docentry is array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'documentation: [[scalar]]'
        """

        assert_raise(RamlParseError, ~r(each documentation section must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if docentry uses wrong property name" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'documentation:',
        '  - title: Getting Started',
        '    content: Getting Started',
        '    wrongPropertyName: Getting Started'
        """

        assert_raise(RamlParseError, ~r(unknown property wrongPropertyName), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if has null title" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'documentation:',
        '  - title:',
        '    content: Getting Started'
        """

        assert_raise(RamlParseError, ~r(title must be a string), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if has null content" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'documentation:',
        '  - title: some title',
        '    content:'
        """

        assert_raise(RamlParseError, ~r(content must be a string), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "Default Media Type" do
      it "should fail if mediaType property is null" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'mediaType:'
        """
        assert_raise(RamlParseError, ~r(mediaType must be a scalar), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if mediaType property is array" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'mediaType: []'
        """
        assert_raise(RamlParseError, ~r(mediaType must be a scalar), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if mediaType property is map" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'mediaType: {}'
        """
        assert_raise(RamlParseError, ~r(mediaType must be a scalar), fn ->
          parse_string!(str)
        end)
      end

      it "should not fail if mediaType property is used in root" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'mediaType: application/json'
        """
        expected = %{title: "MyApi",
                     mediaType: "application/json"
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should fail if mediaType property is not present and implicit mode is detected in a resource" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        '/resource:',
        '  post:',
        '    body:',
        '     example: example of a post',
        """
        assert_raise(RamlParseError, ~r(body tries to use default Media Type, but mediaType is null), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if mediaType property is not present and implicit mode is detected in a trait" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'traits:',
        '  - traitName:',
        '      body:',
        '        example: example of a post',
        '/resource:',
        '  is: [traitName]'
        """
        assert_raise(RamlParseError, ~r(body tries to use default Media Type, but mediaType is null), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if mediaType property is not present and implicit mode is detected in a resourceType" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: MyApi',
        'resourceTypes:',
        '  - typeName:',
        '      post:',
        '        body:',
        '          example: example of a post',
        '/resource:',
        '  type: typeName'
        """
        assert_raise(RamlParseError, ~r(body tries to use default Media Type, but mediaType is null), fn ->
          parse_string!(str)
        end)
      end

      describe "Default Media Type in request body" do
        it "should apply mediaType property in a resource with nullable body" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          '/resource:',
          '  post:',
          '    body:',
          ''
          """
          expected = %{"title" => "MyApi",
                       "mediaType" => "application/json",
                       "resources" => [%{"relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"body" => %{"application/json" => nil},
                                                         "method" => "post"
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should apply mediaType property in a resource" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          '/resource:',
          '  post:',
          '    body:',
          '     example: example of a post',
          """
          expected = %{"title" => "MyApi",
                       "mediaType" => "application/json",
                       "resources" => [%{"relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"body" => %{"application/json" => %{"example" => "example of a post"}},
                                                         "method" => "post"
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should apply mediaType property in a resourceType" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          'resourceTypes:',
          '  - gettable:',
          '      get:',
          '        body:',
          '          example: example of a response',
          '/resource:',
          '  type: gettable'
          """
          expected = %{"title" => "MyApi",
                       "mediaType" => "application/json",
                       "resourceTypes" => [%{"gettable" => %{"get" => %{"body" => %{"example" => "example of a response"}}}}],
                       "resources" => [%{"type" => "gettable",
                                         "relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"body" => %{"application/json" => %{"example" => "example of a response"}},
                                                         "method" => "get"
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should apply mediaType property in a trait composed with a resourceType" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          'resourceTypes:',
          '  - gettable:',
          '      get:',
          '        is: [bodiable]',
          'traits:',
          '  - bodiable:',
          '      body:',
          '        example: example of a response',
          '/resource:',
          '  type: gettable'
          """
          expected = %{"title" => "MyApi",
                       "mediaType" => "application/json",
                       "resourceTypes" => [%{"gettable" => %{"get" => %{"is" => ["bodiable"]}}}],
                       "traits" => [%{"bodiable" => %{"body" => %{"example" => "example of a response"}}}],
                       "resources" => [%{"type" => "gettable",
                                         "relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"body" => %{"application/json" => %{"example" => "example of a response"}},
                                                         "method" => "get"
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should apply mediaType property in a trait composed resource" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          'resourceTypes:',
          '  - gettable:',
          '      get:',
          '        is: [bodiable]',
          'traits:',
          '  - bodiable:',
          '          body:',
          '            example: example of a response',
          '/resource:',
          '  is: [bodiable]',
          '  get:'
          """
          expected = %{"title" => "MyApi",
                       "mediaType" => "application/json",
                       "resourceTypes" => [%{"gettable" => %{"get" => %{"is" => ["bodiable"]}}}],
                       "traits" => [%{"bodiable" => %{"body" => %{"example" => "example of a response"}}}],
                       "resources" => [%{"is" => ["bodiable"],
                                         "relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"body" => %{"application/json" => %{"example" => "example of a response"}},
                                                         "method" => "get"
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should apply mediaType property in a trait composed with a resourceType which inherits from another RT and applies a trait" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          'resourceTypes:',
          '  - gettable:',
          '      type: secondLevel',
          '  - secondLevel:',
          '      is: [bodiable]',
          '      get:',
          '            body:',
          '              schema: composable schema',
          'traits:',
          '  - bodiable:',
          '          body:',
          '            example: example of a response',
          '/resource:',
          '  type: gettable'
          """
          expected = %{"title" => "MyApi",
                       "mediaType" => "application/json",
                       "resourceTypes" => [%{"gettable" => %{"type" => "secondLevel"}},
                                           %{"secondLevel" => %{"is" => ["bodiable"],
                                                                "get" => %{"body" => %{"schema" => "composable schema"}}
                                                               }}
                                          ],
                       "traits" => [%{"bodiable" => %{"body" => %{"example" => "example of a response"}}}],
                       "resources" => [%{"type" => "gettable",
                                         "relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"body" => %{"application/json" => %{"schema" => "composable schema",
                                                                                             "example" => "example of a response"
                                                                                            }},
                                                         "method" => "get"
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should be applied to nested resources" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          '/1:',
          '  /2:',
          '    get:',
          '        body:',
          '          example:'
          """
          {:ok, result} = parse_string(str)
          media_type =
            result
          |> Map.get("resources")
          |> Enum.at(0)
          |> Map.get("resources")
          |> Enum.at(0)
          |> Map.get("methods")
          |> Enum.at(0)
          |> Map.get("body")
          |> Map.get("application/json")

          assert media_type
        end
      end

      describe "Default Media Type in response body" do
        it "should apply mediaType property in a resource" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          '/resource:',
          '  post:',
          '    responses:',
          '      200:',
          '        body:',
          '          example: example of a post'
          """
          expected = %{"title" => "MyApi",
            "mediaType" => "application/json",
            "resources" => [%{"relativeUri" => "/resource",
                              "relativeUriPathSegments" => ["resource"],
                              "methods" => [%{"responses" => %{"200" => %{"body" => %{"application/json" => %{"example" => "example of a post"}}}},
                                              "method" => "post"
                                             }]
                             }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should apply mediaType property in a resourceType" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          'resourceTypes:',
          '  - gettable:',
          '      get:',
          '        responses:',
          '          200:',
          '            body:',
          '              example: example of a response',
          '/resource:',
          '  type: gettable'
          """
          expected = %{"title" => "MyApi",
                       "mediaType" => "application/json",
                       "resourceTypes" => [%{"gettable" => %{"get" => %{"responses" => %{"200" => %{"body" => %{"example" => "example of a response"}}}}}}],
                       "resources" => [%{"type" => "gettable",
                                         "relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"responses" => %{"200" => %{"body" => %{"application/json" => %{"example" => "example of a response"}}}},
                                                         "method" => "get"
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should apply mediaType property in a trait composed with a resourceType" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          'resourceTypes:',
          '  - gettable:',
          '      get:',
          '        is: [bodiable]',
          'traits:',
          '  - bodiable:',
          '      responses:',
          '        200:',
          '          body:',
          '            example: example of a response',
          '/resource:',
          '  type: gettable'
          """
          expected = %{"title" => "MyApi",
                       "mediaType" => "application/json",
                       "resourceTypes" => [%{"gettable" => %{"get" => %{"is" => ["bodiable"]}}}],
                       "traits" => [%{"bodiable" => %{"responses" => %{"200" => %{"body" => %{"example" => "example of a response"}}}}}],
                       "resources" => [%{"type" => "gettable",
                                         "relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"responses" => %{"200" => %{"body" => %{"application/json" => %{"example" => "example of a response"}}}},
                                                         "method" => "get"
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should apply mediaType property in a trait composed resource" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          'resourceTypes:',
          '  - gettable:',
          '      get:',
          '        is: [bodiable]',
          'traits:',
          '  - bodiable:',
          '      responses:',
          '        200:',
          '          body:',
          '            example: example of a response',
          '/resource:',
          '  is: [bodiable]',
          '  get:'
          """
          expected = %{"title" => "MyApi",
                       "mediaType" => "application/json",
                       "resourceTypes" => [%{"gettable" => %{"get" => %{"is" => ["bodiable"]}}}],
                       "traits" => [%{"bodiable" => %{"responses" => %{"200" => %{"body" => %{"example" => "example of a response"}}}}}],
                       "resources" => [%{"is" => ["bodiable"],
                                         "relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"responses" => %{"200" => %{"body" => %{"application/json" => %{"example" => "example of a response"}}}},
                                                         "method" => "get"
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should apply mediaType property in a trait composed with a resourceType which inherits from another RT and applies a trait" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          'resourceTypes:',
          '  - gettable:',
          '      type: secondLevel',
          '  - secondLevel:',
          '      is: [bodiable]',
          '      get:',
          '        responses:',
          '          200:',
          '            body:',
          '              schema: composable schema',
          'traits:',
          '  - bodiable:',
          '      responses:',
          '        200:',
          '          body:',
          '            example: example of a response',
          '/resource:',
          '  type: gettable'
          """
          expected = %{"title" => "MyApi",
                       "mediaType" => "application/json",
                       "resourceTypes" => [%{"gettable" => %{"type" => "secondLevel"}},
                                           %{"secondLevel" => %{"is" => ["bodiable"],
                                                                "get" => %{"responses" => %{"200" => %{"body" => %{"schema" => "composable schema"}}}}
                                                               }}
                                          ],
                       "traits" => [%{"bodiable" => %{"responses" => %{"200" => %{"body" => %{"example" => "example of a response"}}}}}],
                       "resources" => [%{"type" => "gettable",
                                         "relativeUri" => "/resource",
                                         "relativeUriPathSegments" => ["resource"],
                                         "methods" => [%{"responses" => %{"200" => %{"body" => %{"application/json" => %{"schema" => "composable schema",
                                                                                                                         "example" => "example of a response"
                                                                                                                        }}}},
                                                         "method" => "get"
                                                        }]
                                        }]
                      }
          {:ok, result} = parse_string(str)
          assert result == expected
        end

        it "should be applied to nested resources" do
          str = """
          '#%RAML 0.8',
          '---',
          'title: MyApi',
          'mediaType: application/json',
          '/1:',
          '  /2:',
          '    get:',
          '      responses:',
          '        200:',
          '          body:',
          '            example:'
          """
          {:ok, result} = parse_string(str)
          media_type =
            result
          |> Map.get("resources")
          |> Enum.at(0)
          |> Map.get("resources")
          |> Enum.at(0)
          |> Map.get("methods")
          |> Enum.at(0)
          |> Map.get("responses")
          |> Map.get("200")
          |> Map.get("body")
          |> Map.get("application/json")
          assert media_type
        end
      end
    end

    describe "Error reporting" do
      it 'should report correct line/column for invalid trait error' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Test',
        'traits:',
        '  - wrongKey:',
        '      displayName: Rate Limited',
        '      responses:',
        '        503:',
        '          description: Server Unavailable. Check Your Rate Limits.',
        '/:',
        '  is: [ throttled, rateLimited: { parameter: value } ]'
        """
        assert_raise(RamlParseError, fn ->
          {:error, error} = parse_string(str)
          assert error.line == 11
          assert error.column == 9
          raise error
        end)
      end

      it 'should report correct line/column for missing title' do
        str = """
        '#%RAML 0.8',
        '---',
        '/:',
        '  get:'
        """
        assert_raise(RamlParseError, fn ->
          {:error, error} = parse_string(str)
          assert error.line == 3
          assert error.column == 1
          raise error
          end)
      end

      it 'should report correct line/column for missing title' do
        str = """
        '#%RAML 0.8',
        '---'
        """
        assert_raise(RamlParseError, ~r(document must be a map), fn ->
          parse_string!(str)
        end)
      end

      it "should not mark query parameters as required by default" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Title',
        'baseUri: http://server/api',
        '/:',
        '  get:',
        '    queryParameters:',
        '      notRequired:',
        '        type: integer'
        """
        expected = %{"title" => 'Title',
                     "baseUri" => 'http://server/api',
                     "protocols" => ['HTTP'],
                     "resources" => [%{"relativeUriPathSegments" => [],
                                       "relativeUri" => '/',
                                       "methods" => [%{"method" => 'get',
                                                       "protocols" => ['HTTP'],
                                                       "queryParameters" => %{"notRequired" => %{"type" => 'integer',
                                                                                                 "displayName" => 'notRequired'
                                                                                                }}
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should mark query parameters as required when explicitly requested" do
        str = """
        '#%RAML 0.8',
        '---',
        'title: Title',
        'baseUri: http://server/api',
        '/:',
        '  get:',
        '    queryParameters:',
        '      mustBeRequired:',
        '        type: integer',
        '        required: true'
        """
        expected = %{"title" => 'Title',
                     "baseUri" => 'http://server/api',
                     "protocols" => ['HTTP'],
                     "resources" => [%{"relativeUriPathSegments" => [],
                                       "relativeUri" => '/',
                                       "methods" => [%{"method" => 'get',
                                                       "protocols" => ['HTTP'],
                                                       "queryParameters" => %{"mustBeRequired" => %{"type" => 'integer',
                                                                                                    "displayName" => 'mustBeRequired',
                                                                                                    "required" => true
                                                                                                   }}
                                                      }]
                                      }]
                    }
        {:ok, result} = parse_string(str)
        assert result == expected
      end

      it "should report error that contains URI inside" do
        uri = 'http://localhost:9001/invalid/url';
        str = """
        '#%RAML 0.8',
        '---',
        'title: !include #{uri}'
        """
        assert_raise(RamlParseError, ~r(#{uri}), fn ->
          parse_string!(str)
        end)
      end

      it 'should report correct line/column for unavailable file in !include' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: !include unavailable.raml'
        """
        assert_raise(RamlParseError, fn ->
          {:error, error} = parse_string(str)
          assert error.line == 3
          assert error.column == 8
          raise error
        end)
      end

      it 'should report correct line/column for unavailable URI in !include' do
        str = """
        '#%RAML 0.8',
        '---',
        'title: !include http://localhost:9001/invalid/url'
        """
        assert_raise(RamlParseError, fn ->
          {:error, error} = parse_string(str)
          assert error.line == 3
          assert error.column == 8
          raise error
        end)
      end

      it 'should detect circular !include of the same resource' do
        file = 'test/assets/RT-261.raml'
        assert_raise(RamlParseError, ~r(circular include detected), fn ->
          parse_file!(file)
        end)
      end
    end
  end
end
