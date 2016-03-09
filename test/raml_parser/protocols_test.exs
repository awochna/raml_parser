defmodule RamlParser.ProtocolsTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/protocols.js
  """

  use ExSpec, async: true
  import RamlParser

  describe "Protocols" do
    it "should use value from baseUri property for protocols property if not specified explicitly" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      """
      expected = %{"title" => "Example",
                   "baseUri" => "http://api.com",
                   "protocols" => ["HTTP"]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should apply root protocols to methods" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      /:
         get:
      """
      expected = %{"title" => "Example",
                   "baseUri" => "http://api.com",
                   "protocols" => ["HTTP"],
                   "resources" => [%{"relativeUriPathSegments" => [],
                                     "relativeUri" => "/",
                                     "methods" => [%{"method" => "get",
                                                     "protocols" => ["HTTP"]
                                                    }]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should inherit protocols from traits" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: http://api.com
      traits:
         - trait1:
             protocols:
                 - HTTP
                 - HTTPS
      /:
         get:
             is:
                 - trait1
      """
      expected = %{"title" => "Example",
                   "baseUri" => "http://api.com",
                   "protocols" => ["HTTP"],
                   "traits" => [%{"trait1" => %{"protocols" => ["HTTP", "HTTPS"]}}],
                   "resources" => [%{"relativeUriPathSegments" => [],
                                     "relativeUri" => "/",
                                     "methods" => [%{"method" => "get",
                                                     "is" => ["trait1"],
                                                     "protocols" => ["HTTP", "HTTPS"]
                                                    }]
                                    }]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end

    it "should assume HTTP protocol by default if there is no protocols property and baseUri has no protocol either" do
      str = """
      #%RAML 0.8
      ---
      title: Example
      baseUri: api.com
      """
      expected = %{"title" => "Example",
                   "baseUri" => "api.com",
                   "protocols" => ["HTTP"]
                  }
      {:ok, result} = parse_string(str)
      assert result == expected
    end
  end
end
