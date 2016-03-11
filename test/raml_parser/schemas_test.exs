defmodule RamlParser.SchemasTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/schemas.js
  """

  use ExSpec, async: true
  import RamlParser

  describe "Schemas" do
    it "should replace the value of a schema by default" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      schemas:
         - foo: |
             some value here
      /foo:
        post:
          body:
            application/json:
              schema: foo
      """
      expected = %{"title" => "Example",
                   "schemas" => [%{"foo" => "some value here\n"}],
                   "resources" => [%{"relativeUri" => "/foo",
                                     "methods" => [%{"body" => %{"application/json" => %{"schema" => "some value here\n"}},
                                                     "method" => "post"
                                                    }],
                                     "relativeUriPathSegments" => ["foo"]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should replace the value of a schema by default when feature flag is enabled" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      schemas:
         - foo: |
             some value here
      /foo:
        post:
          body:
            application/json:
              schema: foo
      """
      expected = %{"title" => "Example",
                   "schemas" => [%{"foo" => "some value here\n"}],
                   "resources" => [%{"relativeUri" => "/foo",
                                     "methods" => [%{"body" => %{"application/json" => %{"schema" => "some value here\n"}},
                                                     "method" => "post"
                                                    }],
                                     "relativeUriPathSegments" => ["foo"]
                                    }]
                  }
      {:ok, result} = parse_string(str, applySchemas: true)
      assert result == expected
    end

    it "should not replace the value of a schema by default when feature flag is disabled" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      schemas:
         - foo: |
             some value here
      /foo:
        post:
          body:
            application/json:
              schema: foo
      """
      expected = %{"title" => "Example",
                   "schemas" => [%{"foo" => "some value here\n"}],
                   "resources" => [%{"relativeUri" => "/foo",
                                     "methods" => [%{"body" => %{"application/json" => %{"schema" => "foo"}},
                                                     "method" => "post"
                                                    }],
                                     "relativeUriPathSegments" => ["foo"]
                                    }]
                  }
      {:ok, result} = parse_string(str, applySchemas: false)
      assert result == expected
    end
  end
end
