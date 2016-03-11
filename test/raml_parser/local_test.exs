defmodule RamlParser.LocalTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/local.js
  """

  use ExSpec, async: true
  import RamlParser

  describe "Parser" do
    describe "Include" do
      it "should succeed on including local files" do
        expected = %{"title" => "MyApi",
                     "documentation" => [
                       %{"title" => "Getting Started",
                         "content" => "# Getting Started\n\nThis is a getting started guide"
                        }
                     ]
                    }
        {:ok, result} = parse_file("test/assets/local.yml")
        assert result == expected
      end
    end
  end
end
