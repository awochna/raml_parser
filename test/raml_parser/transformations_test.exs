defmodule RamlParser.TransformationsTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/transformations.js
  """

  use ExSpec, async: true
  import RamlParser

  describe "Transformations" do
    describe "named parameters" do
      describe "required by default" do
        it "for base uri parameters at root level" do
          str = """
          #%RAML 0.8
          ---
          title: My API
          baseUri: http://base.uri/{baseUriParameter1}
          """
          {:ok, result} = parse_string(str)
          %{"baseUriParameters" => %{"baseUriParameter1" => %{"required" => required}}} = result
          assert required == true
        end

        it "for uri parameters at resource level" do
          str = """
          #%RAML 0.8
          ---
          title: My API
          /{uriParameter1}:
          """
          {:ok, result} = parse_string(str)
          %{"resources" => [%{"uriParameters" => %{"uriParameter1" => %{"required" => required}}} | _]} = result
          assert required == true
        end
      end

      describe "NOT required by default" do
        it "for request headers" do
          str = """
          #%RAML 0.8
          ---
          title: My API
          /:
            get:
              headers:
                header1: {}
          """
          {:ok, result} = parse_string(str)
          header =
            result
          |> Map.get("resources")
          |> Enum.at(0)
          |> Map.get("methods")
          |> Enum.at(0)
          |> Map.get("headers")
          |> Map.get("header1")

          assert header
          assert Map.has_key?(header, "required") == false
        end

        it "for response headers" do
          str = """
          #%RAML 0.8
          ---
          title: My API
          /:
            get:
              responses:
                200:
                  headers:
                    header1:
          """
          {:ok, result} = parse_string(str)
          header =
            result
          |> Map.get("resources")
          |> Enum.at(0)
          |> Map.get("methods")
          |> Enum.at(0)
          |> Map.get("responses")
          |> Map.get("200")
          |> Map.get("headers")
          |> Map.get("header1")

          assert header
          assert Map.has_key?(header, "required") == false
        end

        it "for queryParameters" do
          str = """
          #%RAML 0.8
          ---
          title: My API
          /:
            get:
              queryParameters:
                queryParameter1:
          """
          {:ok, result} = parse_string(str)
          parameter =
            result
          |> Map.get("resources")
          |> Enum.at(0)
          |> Map.get("methods")
          |> Map.get("queryParameters")
          |> Map.get("queryParameter1")

          assert parameter
          assert Map.has_key?(parameter, "required") == false
        end

        it "for formParameters" do
          str = """
          #%RAML 0.8
          ---
          title: My API
          /:
            post:
              body:
                application/x-www-form-urlencoded:
                  formParameters:
                    formParameter1:
          """
          {:ok, result} = parse_string(str)
          parameter =
            result
          |> Map.get("resources")
          |> Enum.at(0)
          |> Map.get("methods")
          |> Enum.at(0)
          |> Map.get("body")
          |> Map.get("application/x-www-form-urlencoded")
          |> Map.get("formParameters")
          |> Map.get("formParameter1")

          assert parameter
          assert Map.has_key?(parameter, "required") == false
        end
      end
    end

    it "should fill empty named parameters with default values like displayName and type" do
      str = """
      #%RAML 0.8
      ---
      title: Title
      baseUri: http://server/api
      /:
        get:
          queryParameters:
            parameter1:
      """
      expected = %{"title" => "Title",
                   "baseUri" => "http://server/api",
                   "protocols" => ["HTTP"],
                   "resources" => [%{"relativeUriPathSegments" => [],
                                     "relativeUri" => "/",
                                     "methods" => [%{"method" => "get",
                                                     "protocols" => ["HTTP"],
                                                     "queryParameters" => %{"parameter1" => %{"displayName" => "parameter1",
                                                                                              "type" => "string"
                                                                                             }}
                                                    }]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end
  end
end
