defmodule RamlParser.RegressionsTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/regressions.js
  """

  use ExSpec, async: true
  import RamlParser

  describe "Regressions" do
    it "should fail unsupported raml version:RT-180" do
      str = """
      '#%RAML 0.1'
      """

      assert_raise(RamlParseError, ~r(Unsupported RAML version: \'#%RAML 0.1\'), fn ->
        parse_string!(str)
      end)
    end

    it "should fail with correct error message on hex values" do
      str = """
      '#%RAML 0.8',
      'some_key: "some value \\x0t"'
      """

      assert_raise(RamlParseError, ~r(expected escape sequence of 2 hexadecimal numbers, but found t), fn ->
        parse_string!(str)
      end)
    end

    it "should fail when mapping keys are present" do
      str = """
      '#%RAML 0.8',
      'some_key: ? something : something'
      """

      assert_raise(RamlParseError, ~r(mapping keys are not allowed here), fn ->
        parse_string!(str)
      end)
    end

    it "should fail if baseUriParameter is not a map" do
      str = """
      '#%RAML 0.8',
      'title: Test',
      'baseUri: http://www.api.com/{version}/{company}',
      'version: v1.1',
      '/jobs:',
      '  baseUriParameters:',
      '    company:',
      '      description'
      """

      assert_raise(RamlParseError, ~r(parameter must be a map), fn ->
        parse_string!(str)
      end)
    end

    it "should not fail to parse an empty trait" do
      str = """
      '#%RAML 0.8',
      'title: MyApi',
      'traits:',
      '  - emptyTrait:',
      '    otherTrait:',
      '      description: Some description',
      """
      assert_raise(RamlParseError, ~r(invalid trait definition, it must be a map), fn ->
        parse_string!(str)
      end)
    end

    it "should not fail to parse an empty trait list" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: Test',
      'baseUri: http://www.api.com/{version}/{company}',
      'version: v1.1',
      'traits:'
      """
      assert_raise(RamlParseError, ~r(invalid traits definition, it must be an array), fn ->
        parse_string!(str)
      end)
    end

    it "should fail to parse a RAML header " do
      str = """
      '#%RAML 0.8'
      """
      assert_raise(RamlParseError, ~r(empty document), fn ->
        parse_string!(str)
      end)
    end

    it "should not fail to parse a RAML file only with headers" do
      str = """
      '#%RAML 0.8',
      '---'
      """
      assert_raise(RamlParseError, ~r(document must be a map), fn ->
        parse_string!(str)
      end)
    end

    it "should not fail to parse a RAML null uriParameters. RT-178" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: hola',
      'version: v0.1',
      'baseUri: http://server/api/{version}',
      'baseUriParameters:'
      """
      expected = %{"title" => "hola",
                   "version" => "v0.1",
                   "baseUri" => "http://server/api/{version}",
                   "baseUriParameters" => %{"version" => %{"type" => "string",
                                                           "required" => true,
                                                           "displayName" => "version",
                                                           "enum" => ["v0.1"]
                                                          }},
                   "protocols" => ["HTTP"]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should fail if baseUriParamters has a version parameter. RT-199" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: hola',
      'version: v0.1',
      'baseUri: http://server/api/{version}',
      'baseUriParameters:',
      ' version:'
      """
      assert_raise(RamlParseError, ~r(version parameter not allowed here), fn ->
        parse_string!(str)
      end)
    end

    it "should fail if resource URI is invalid" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: hola',
      'version: v0.1',
      '/resourceName{}:'
      """
      assert_raise(RamlParseError, ~r(Resource name is invalid:), fn ->
        parse_string!(str)
      end)
    end

    it "should fail if baseUriParameters is a string - RT-274" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: hola',
      'version: v0.1',
      'baseUri: http://example.com',
      'baseUriParameters:',
      '  someparam'
      """
      assert_raise(RamlParseError, ~r(base uri parameters must be a map), fn ->
        parse_string!(str)
      end)
    end

    it "should fail if baseUriParameters is a string - RT-274 - with proper line numbering" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: hola',
      'version: v0.1',
      'baseUri: http://example.com',
      'baseUriParameters:',
      '  someparam'
      """
      assert_raise(RamlParseError, ~r(base uri parameters must be a map), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 7
        assert error.column == 3
        raise error
      end)
    end

    it "should fail if baseUriParameters in a resource is a string - RT-274" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: hola',
      'version: v0.1',
      'baseUri: http://localhost',
      '/resource:',
      '  baseUriParameters:',
      '    someparam'
      """
      assert_raise(RamlParseError, ~r(base uri parameters must be a map), fn ->
        parse_string!(str)
      end)
    end

    it "should fail if iParameters in a resource is a string - RT-274" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: hola',
      'version: v0.1',
      'baseUri: http://localhost',
      '/resource:',
      '  uriParameters:',
      '    someparam'
      """
      assert_raise(RamlParseError, ~r(uri parameters must be a map), fn ->
        parse_string!(str)
      end)
    end

    it "should report correct line (RT-244)" do
      str = """
      '',
      ''
      """
      assert_raise(RamlParseError, fn ->
        {:error, error} = parse_string(str)
        assert error.line == 1
        assert error.column == 1
        raise error
      end)
    end

    it "should report correct line for null media type in implicit mode" do
      str = """
      '#%RAML 0.8',
      '/resource:',
      '  post:',
      '    body:',
      '      schema: someSchema'
      """
      assert_raise(RamlParseError, ~r(body tries to use default Media Type, but mediaType is null), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 4
        assert error.column == 5
        raise error
      end)
    end

    it "should report repeated URIs in the second URIs line - RT-279" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: "muse:"',
      'baseUri: http://ces.com/muse',
      '/r1/r2:',
      '/r1:',
      '  /r2:'
      """
      assert_raise(RamlParseError, ~r(two resources share same URI /r1/r2), fn ->
        {:error, error} = parse_string(str)
        assert error.line  == 7
        assert error.column == 3
        raise error
      end)
    end

    it "should allow a trait parameter with an integer value - RT-279" do
      str = """
      '#%RAML 0.8',
      '---',
      'traits:',
      '  - getMethod:',
      '     description: <<description>>',
      'title: title',
      '/test:',
      ' is: [ getMethod: { description: 1 }]'
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should allow a resource type parameter with an integer value - RT-279" do
      str = """
      '#%RAML 0.8',
      '---',
      'resourceTypes:',
      '  - someType:',
      '     description: <<description>>',
      'title: title',
      '/test:',
      ' type: { someType: { description: 1 }}'
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "should apply a resourceType that inherits from another type that uses parameters" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: My API',
      'resourceTypes:',
      '  - base:',
      '      get:',
      '         description: <<description>>',
      '  - collection:',
      '      type: { base: { description: hola } }',
      '      get:',
      '  - typedCollection:',
      '      type: collection',
      '      get:',
      '         description: <<description>>',
      '/presentations:',
      '  type: { typedCollection: { description: description } }'
      """

      expected = %{"title" => "My API",
                   "resourceTypes" => [%{"base" => %{"get" => %{"description" => "<<description>>"}}},
                                       %{"collection" => %{"type" => %{"base" => %{"description" => "hola"}},
                                                           "get" => nil
                                                          }},
                                       %{"typedCollection" => %{"type" => "collection",
                                                                "get" => %{"description" => "<<description>>"}
                                                               }}
                                      ],
                   "resources" => [%{"type" => %{"typedCollection" => %{"description" => "description"}},
                                     "relativeUri" => "/presentations",
                                     "methods" => [%{"method" => "get",
                                                     "description" => "description"
                                                    }],
                                     "relativeUriPathSegments" => ["presentations"]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should report correct line for resourceType not map error - RT-283" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: "muse:"',
      'resourceTypes:',
      '  - type1: {}',
      '    type:'
      """
      assert_raise(RamlParseError, ~r(invalid resourceType definition, it must be a map), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 6
        assert error.column == 10
        raise error
      end)
    end

    it "should report correct line for resourceType circular reference - RT-257" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: "muse:"',
      'resourceTypes:',
      '  - rt1:',
      '      type: rt2',
      '  - rt2:',
      '      type: rt1',
      '/resource:',
      '  type: rt1'
      """
      assert_raise(RamlParseError, ~r(circular reference of 'rt1' has been detected: rt1 -> rt2 -> rt1), fn ->
        {:error, error} = parse_string(str)
        assert error.line == 7
        assert error.column == 5
        raise error
      end)
    end

    it "should apply a trait to a method that has been applied a resource type with a matching null method" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: User Management',
      'traits:',
      '  - paged:',
      '      queryParameters:',
      '        start:',
      'resourceTypes:',
      '  - collection:',
      '      get:',
      '/users:',
      '  type: collection',
      '  get:',
      '    is: [ paged ]'
      """

      expected = %{"title" => "User Management",
                   "traits" => [%{"paged" => %{"queryParameters" => %{"start" => %{"displayName" => "start",
                                                                                   "type" => "string"
                                                                                  }}}}],
                   "resourceTypes" => [%{"collection" => %{"get" => nil}}],
                   "resources" => [%{"type" => "collection",
                                     "relativeUri" => "/users",
                                     "relativeUriPathSegments" => ["users"],
                                     "methods" => [%{"queryParameters" => %{"start" => %{"displayName" => "start",
                                                                                         "type" => "string"
                                                                                        }},
                                                     "is" => ["paged"],
                                                     "method" => "get"
                                                    }]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should clone references instead of using reference" do
      str = """
      '#%RAML 0.8',
      'title: My api',
      'version: v1',
      '/res1: &res1',
      '  description: this is res1 description',
      '  displayName: resource 1',
      '  get:',
      '    description: get into resource 1',
      '/res2: *res1'
      """

      expected = %{"title" => "My api",
                   "version" => "v1",
                   "resources" => [%{"description" => "this is res1 description",
                                     "displayName" => "resource 1",
                                     "relativeUri" => "/res1",
                                     "methods" => [%{"description" => "get into resource 1",
                                                     "method" => "get"
                                                    }],
                                     "relativeUriPathSegments" => ["res1"]
                                    },
                                   %{"description" => "this is res1 description",
                                     "displayName" => "resource 1",
                                     "relativeUri" => "/res2",
                                     "methods" => [%{"description" => "get into resource 1",
                                                     "method" => "get"
                                                    }],
                                     "relativeUriPathSegments" => ["res2"]
                                    }
                                  ]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should handle a resource and sub-resource named /protocols" do
      str = """
      '#%RAML 0.8',
      'title: My api',
      '/protocols:',
      '  /protocols:'
      """
      expected = %{"title" => "My api",
                   "resources" => [%{"relativeUri" => "/protocols",
                                     "relativeUriPathSegments" => ["protocols"],
                                     "resources" => [%{"relativeUri" => "/protocols",
                                                       "relativeUriPathSegments" => ["protocols"]
                                                      }]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should handle a resource and sub-resource named /type.*" do
      str = """
      '#%RAML 0.8',
      'title: My api',
      'resourceTypes:',
      '    - ref: {}',
      '/type_:',
      '  /type_someword:',
      '    get:'
      """
      expected = %{"title" => "My api",
                   "resourceTypes" => [%{"ref" => %{}}],
                   "resources" => [%{"relativeUri" => "/type_",
                                     "resources" => [%{"relativeUri" => "/type_someword",
                                                       "methods" => [%{"method" => "get"}],
                                                       "relativeUriPathSegments" => ["type_someword"]
                                                      }],
                                     "relativeUriPathSegments" => ["type_"]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should not download a null named file. RT-259" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: !include'
      """

      assert_raise(RamlParseError, ~r(file name\/URL cannot be null), fn ->
        parse_string!(str)
      end)
    end

    it "should not download a file named with blanks. RT-259" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: !include             '
      """

      assert_raise(RamlParseError, ~r(file name\/URL cannot be null), fn ->
        parse_string!(str)
      end)
    end

    it "should not fail with null responses" do
      str = """
      '#%RAML 0.8',
      'title: GitHub API',
      '/res:',
      '  get:',
      '    responses:'
      """
      {:ok, result} = parse_string(str)
      assert result
    end

    it "add a regression test for a complex RAML file" do
      str = """
      '#%RAML 0.8',
      '---',
      '!include http://localhost:9001/test/raml-files/regression.yml'
      """

      {:ok, result} = parse_string(str)
      assert result
    end

    it "add a regression test for a big RAML file" do
      str = """
      '#%RAML 0.8',
      '---',
      '!include http://localhost:9001/test/raml-files/large-raml.yml'
      """

      {:ok, result} = parse_string(str)
      assert result
    end

    it "add a regression test that composeFile does not fail" do
      str = """
      '#%RAML 0.8',
      '---',
      '!include http://localhost:9001/test/raml-files/large-raml.yml'
      """

      {:ok, result} = parse_string(str)
      assert result
    end

    it "should handle optional parameters onto optional parameters merge correctly" do
      str = """
      '#%RAML 0.8',
      'title: Title',
      'resourceTypes:',
      '  - common:',
      '      get?:',
      '  - base:',
      '      type: common',
      '      get?:',
      '/files:',
      '  type: base',
      '  post:'
      """
      expected = %{"title" => "Title",
                   "resourceTypes" => [%{"common" => %{"get?" => nil}},
                                       %{"base" => %{"type" => "common",
                                                     "get?" => nil
                                                    }}
                                      ],
                   "resources" => [%{"type" => "base",
                                     "relativeUri" => "/files",
                                     "methods" => [%{"method" => "post"}],
                                     "relativeUriPathSegments" => ["files"]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should handle optional parameters onto null parameters merge correctly" do
      str = """
      '#%RAML 0.8',
      'title: Title',
      'resourceTypes:',
      '  - common: {}',
      '  - base:',
      '      type: common',
      '      get?:',
      '/files:',
      '  type: base',
      '  post:'
      """
      expected = %{"title" => "Title",
                   "resourceTypes" => [%{"common" => %{}},
                                       %{"base" => %{"type" => "common",
                                                     "get?" => nil
                                                    }}
                                      ],
                   "resources" => [%{"type" => "base",
                                     "relativeUri" => "/files",
                                     "methods" => [%{"method" => "post"}],
                                     "relativeUriPathSegments" => ["files"]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should handle null parameters onto optional parameters merge correctly" do
      str = """
      '#%RAML 0.8',
      'title: Title',
      'resourceTypes:',
      '  - common:',
      '      get?:',
      '  - base:',
      '      type: common',
      '/files:',
      '  type: base',
      '  post:'
      """
      expected = %{"title" => "Title",
                   "resourceTypes" => [%{"common" => %{"get?" => nil}},
                                       %{"base" => %{"type" => "common"}}
                                      ],
                   "resources" => [%{"type" => "base",
                                     "relativeUri" => "/files",
                                     "methods" => [%{"method" => "post"}],
                                     "relativeUriPathSegments" => ["files"]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should parse multiple parameters in the same line" do
      str = """
      '#%RAML 0.8',
      'title: Example',
      'resourceTypes:',
      '  - readOnlyCollectionItem:',
      '      description: Retrieve <<resourcePathName|!singularize>> where <<key>> equals **{<<key>>}**',
      '/{widgetName}:',
      '  type:',
      '    readOnlyCollectionItem:',
      '      key: widgetName'
      """
      expected = %{"title" => "Example",
                   "resourceTypes" => [%{"readOnlyCollectionItem" => %{"description" => "Retrieve <<resourcePathName|!singularize>> where <<key>> equals **{<<key>>}**"}}],
                   "resources" => [%{"description" => "Retrieve  where widgetName equals **{widgetName}**",
                                     "type" => %{"readOnlyCollectionItem" => %{"key" => "widgetName"}},
                                     "relativeUri" => "/{widgetName}",
                                     "relativeUriPathSegments" => ["{widgetName}"],
                                     "uriParameters" => %{"widgetName" => %{"type" => "string",
                                                                            "required" => true,
                                                                            "displayName" => "widgetName"
                                                                           }}
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should singularize words properly" do
      str = """
      '#%RAML 0.8',
      '---',
      'title: Example',
      'mediaType: application/json',
      'resourceTypes:',
      '  - collection:',
      '      get:',
      '        responses:',
      '          200:',
      '            body:',
      '              schema: <<resourcePathName | !singularize>>',
      '/waves:',
      '  type: collection'
      """

      expected = %{"title" => "Example",
                   "mediaType" => "application/json",
                   "resourceTypes" => [%{"collection" => %{"get" => %{"responses" => %{"200" => %{"body" => %{"schema" => "<<resourcePathName | !singularize>>"}}}}}}],
                   "resources" => [%{"type" => "collection",
                                     "relativeUri" => "/waves",
                                     "methods" => [%{"responses" => %{"200" => %{"body" => %{"application/json" =>  %{"schema" => "wave"}}}},
                                                     "method" => "get"
                                                    }],
                                     "relativeUriPathSegments" => ["waves"]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should accept description in responses" do
      str = """
      '#%RAML 0.8',
      'title: Title',
      '/example:',
      '  get:',
      '    responses:',
      '      200:',
      '        body:',
      '          "*/*":',
      '            description: |',
      '              This is an example.'
      """

      expected = %{"title" => "Title",
                   "resources" => [%{"relativeUri" => "/example",
                                     "methods" => [%{"method" => "get",
                                                     "responses" => %{"200" => %{"body" => %{"*/*": %{"description" => "This is an example."}}}}
                                                    }],
                                     "relativeUriPathSegments" => ["example"]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should json parse unicode encoding" do
      str = """
      '#%RAML 0.8',
      'title: Title',
      '/:',
      '  post:',
      '    body:',
      '      application/json:',
      '        schema: |',
      '          {',
      '            "type": "string",',
      '            "pattern": "^[A-Z\u017D\\u017E]*$"',
      '          }'
      """

      expected = %{"title" => "Title",
                   "resources" => [%{"relativeUri" => "/",
                                     "methods" => [%{"body" => %{"application/json": %{"schema" => "{\n  \"type\": \"string\",\n  \"pattern\": \"^[A-ZŽ\\u017E]*$\"\n}"}},
                                                     "method" => "post"
                                                    }],
                                     "relativeUriPathSegments" => []
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end
  end
end
