defmodule RamlParser.DuplicateKeysValidationsTest do
  @moduledoc """
  https://github.com/raml-org/raml-js-parser/blob/master/test/specs/duplicateKeysValidations.js
  """

  use ExSpec, async: true
  import RamlParser

  describe "Duplicated properties" do
    describe "in Security Schemes" do
      it "should fail if a security scheme repeats the type property" do
        str = """
        #%RAML 0.8
        title: some API
        securitySchemes:
          - scheme1:
              type: x-custom
              type: x-custom-2
        """

        assert_raise(RamlParseError, ~r(property already used in security scheme: 'type'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if a OAuth 2.0 settings repeats a known property" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        securitySchemes:
         - scheme:
             description: This is some text
             type: OAuth 2.0
             settings:
               authorizationUri: https://www.dropbox.com/1/oauth2/authorize
               accessTokenUri: https://api.dropbox.com/1/oauth2/token
               authorizationGrants: [ code, token ]
               authorizationUri: https://www.dropbox.com/1/oauth2/authorize
        """

        assert_raise(RamlParseError, ~r(setting with the same name already exists: 'authorizationUri'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if a OAuth 2.0 settings repeats an unknown property" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        securitySchemes:
         - scheme:
             description: This is some text
             type: OAuth 2.0
             settings:
               authorizationUri: https://www.dropbox.com/1/oauth2/authorize
               tokenTTL: 60s
               accessTokenUri: https://api.dropbox.com/1/oauth2/token
               authorizationGrants: [ code, token ]
               tokenTTL: 30s
        """

        assert_raise(RamlParseError, ~r(setting with the same name already exists: 'tokenTTL'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if a OAuth 1.0 settings repeats a known property" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        securitySchemes:
         - scheme:
             description: This is some text
             type: OAuth 1.0
             settings:
               requestTokenUri: https://api.dropbox.com/1/oauth/request_token
               authorizationUri: https://www.dropbox.com/1/oauth/authorize
               tokenCredentialsUri: https://api.dropbox.com/1/oauth/access_token
               requestTokenUri: https://api.dropbox.com/1/oauth/request_token
        """

        assert_raise(RamlParseError, ~r(setting with the same name already exists: 'requestTokenUri'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if a OAuth 1.0 settings repeats an unknown property" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        securitySchemes:
         - scheme:
             description: This is some text
             type: OAuth 1.0
             settings:
               requestTokenUri: https://api.dropbox.com/1/oauth/request_token
               requestTimeout: 30
               authorizationUri: https://www.dropbox.com/1/oauth/authorize
               tokenCredentialsUri: https://api.dropbox.com/1/oauth/access_token
               requestTimeout: 30
        """

        assert_raise(RamlParseError, ~r(setting with the same name already exists: 'requestTimeout'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in URI parameters" do
      it "should fail if there are repeated base URI parameter names at the root level" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        baseUri: http://api.com/{param1}
        baseUriParameters:
         param1:
         param1:
        """

        assert_raise(RamlParseError, ~r(URI parameter with the same name already exists: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a base URI parameter at the root level" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        baseUri: http://api.com/{param1}
        baseUriParameters:
         param1:
           type: number
           type: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'type'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated base URI parameter names in a resource" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        baseUri: http://api.com/{param1}
        /resource:
          baseUriParameters:
            param1:
            param1:
        """

        assert_raise(RamlParseError, ~r(URI parameter with the same name already exists: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a base URI parameter in a resource" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        baseUri: http://api.com/{param1}
        /resource:
          baseUriParameters:
            param1:
              type: number
              type: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'type'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated URI parameter names in a resource" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        baseUri: http://api.com/{param1}
        /resource/{param1}:
          uriParameters:
            param1:
            param1:
        """

        assert_raise(RamlParseError, ~r(URI parameter with the same name already exists: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a URI parameter in a resource" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        baseUri: http://api.com/{param1}
        /resource/{param1}:
          uriParameters:
            param1:
              type: number
              type: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'type'), fn ->
          parse_string!(str)
        end)
      end
    end
    describe "in root" do
      it "should fail if there are repeated root properties" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        title: Test
        """

        assert_raise(RamlParseError, ~r(root property already used: 'title'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in documentation" do
      it "should fail if there are repeated doc section titles" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        documentation:
          - title: Title for the section
            content: Content for the section
          - title: Title for the section
            content: Content for the section
          - title: Title for the section
            content: Content for the section
          - title: Title for the section
            content: Content for the section
          - title: Title for the section
            content: Content for the section
          - title: Title for the section
            title: Content for the section
        """

        assert_raise(RamlParseError, ~r(property already used: 'title'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated doc section content" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        documentation:
          - title: Title for the section
            content: Content for the section
            content: Content for the section
        """

        assert_raise(RamlParseError, ~r(property already used: 'content'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in resource names" do
      it "should fail if there are repeated resources in the document" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource:
        /resource:
        """

        assert_raise(RamlParseError, ~r(resource already declared: '\/resource'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated resources in a resource" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource1:
          /resource:
          /resource2:
          /resource:
        """

        assert_raise(RamlParseError, ~r(resource already declared: '\/resource'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in method names" do
      it "should fail if there are repeated methods in a resource" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource1:
          post:
          get:
          head:
          get:
        """

        assert_raise(RamlParseError, ~r(method already declared: 'get'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated methods in a resource type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
              get:
              head:
              get:
        """

        assert_raise(RamlParseError, ~r(method already declared: 'get'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated methods in a resource type first declaration optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
              get?:
              head:
              get:
        """

        assert_raise(RamlParseError, ~r(method already declared: 'get'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated methods in a resource type second declaration optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
              get:
              head:
              get?:
        """

        assert_raise(RamlParseError, ~r(method already declared: 'get'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated methods in a resource type both declarations optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
              get?:
              head:
              get?:
        """

        assert_raise(RamlParseError, ~r(method already declared: 'get'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated methods in a resource type both declarations parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
              <<retieveMethodName>>:
              head:
              <<retieveMethodName>>:
        """

        assert_raise(RamlParseError, ~r(property already used: '<<retieveMethodName>>'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in a resource" do
      it "should fail if there are repeated properties in a resource" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource1:
          description: Some description here
          description: Some other description here
        """

        assert_raise(RamlParseError, ~r(property already used: 'description'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a resource type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              description: Some description here
              description: Some other description here
        """

        assert_raise(RamlParseError, ~r(property already used: 'description'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a resource type first declaration optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              uriParameters?:
              uriParameters:
        """

        assert_raise(RamlParseError, ~r(property already used: 'uriParameters'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a resource type second declaration optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              uriParameters:
              uriParameters?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'uriParameters'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a resource type both declarations optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              uriParameters?:
              uriParameters?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'uriParameters'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in a method" do
      it "should fail if there are repeated properties in a method" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource:
          get:
            body:
            body:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a trait" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
              body:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a trait first declararion optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body?:
              body:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a trait second declaration optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
              body?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a trait both declarations optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body?:
              body?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a trait both declarations parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              <<propertyName>>:
              <<propertyName>>:
        """

        assert_raise(RamlParseError, ~r(property already used: '<<propertyName>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a method in a resource type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                body:
                body:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a method in a resource type first declararion optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                body?:
                body:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a method in a resource type second declaration optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                body:
                body?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a method in a resource type both declarations optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                body?:
                body?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a method in a resource type both declarations parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                <<propertyName>>:
                <<propertyName>>:
        """

        assert_raise(RamlParseError, ~r(property already used: '<<propertyName>>'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in response codes" do
      it "should fail if there are repeated response codes in a method" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource:
          get:
            responses:
              200:
              201:
              209:
              200:
        """

        assert_raise(RamlParseError, ~r(response code already used: '200'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated response codes in a trait" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              responses?:
                200:
                201:
                209:
                200:
        """

        assert_raise(RamlParseError, ~r(response code already used: '200'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated response codes in a trait first declararion optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              responses?:
                200?:
                201:
                209:
                200:
        """

        assert_raise(RamlParseError, ~r(response code already used: '200'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated response codes in a trait second declaration optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              responses?:
                200:
                201:
                209:
                200?:
        """

        assert_raise(RamlParseError, ~r(response code already used: '200'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated response codes in a trait both declarations optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              responses?:
                200?:
                201:
                209:
                200?:
        """

        assert_raise(RamlParseError, ~r(response code already used: '200'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated response codes in a trait both declarations parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              responses?:
                <<successCode>>:
                201:
                209:
                <<successCode>>:
        """

        assert_raise(RamlParseError, ~r(response code already used: '<<successCode>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated response codes in a method in a resource type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                responses?:
                  200:
                  201:
                  204:
                  200:
        """

        assert_raise(RamlParseError, ~r(response code already used: '200'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated response codes in a method in a resource type first declararion optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                responses?:
                  200?:
                  201:
                  204:
                  200:
        """

        assert_raise(RamlParseError, ~r(response code already used: '200'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated response codes in a method in a resource type second declaration optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                responses?:
                  200:
                  201:
                  204:
                  200?:
        """

        assert_raise(RamlParseError, ~r(response code already used: '200'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated response codes in a method in a resource type both declarations optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                responses?:
                  200?:
                  201:
                  204:
                  200?:
        """

        assert_raise(RamlParseError, ~r(response code already used: '200'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated response codes in a method in a resource type both declarations parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                responses?:
                  <<successCode>>:
                  201:
                  204:
                  <<successCode>>:
        """

        assert_raise(RamlParseError, ~r(response code already used: '<<successCode>>'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in responses" do
      it "should fail if there are repeated properties in a response in a method" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource:
          get:
            responses:
              200:
                description: some description
                description: some other description
        """

        assert_raise(RamlParseError, ~r(property already used: 'description'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a response in a trait" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              responses?:
                200?:
                  description: some description
                  description: some other description
        """

        assert_raise(RamlParseError, ~r(property already used: 'description'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a response in a trait first declararion optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              responses?:
                200?:
                  body?:
                  body:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a response in a trait second declaration optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              responses?:
                200?:
                  body:
                  body?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a response in a trait both declarations optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              responses?:
                200?:
                  body?:
                  body?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a response in a trait both declarations parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              responses?:
                200?:
                  <<somePropertyName>>: some description
                  <<somePropertyName>>: some other description
        """

        assert_raise(RamlParseError, ~r(property already used: '<<somePropertyName>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a response in a method in a resource type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                responses?:
                  200?:
                    description: some description
                    description: some other description
        """

        assert_raise(RamlParseError, ~r(property already used: 'description'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a response in a method in a resource type first declararion optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                responses?:
                  200?:
                    body?:
                    body:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a response in a method in a resource type second declaration optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                responses?:
                  200?:
                    body:
                    body?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a response in a method in a resource type both declarations optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                responses?:
                  200?:
                    body?:
                    body?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'body'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a response in a method in a resource type both declarations parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              post:
                responses?:
                  200?:
                    <<someParam>>: some description
                    <<someParam>>: some other description
        """

        assert_raise(RamlParseError, ~r(property already used: '<<someParam>>'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in query parameters" do
      it "should fail if there are repeated query parameter names in a method" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource:
          get:
            queryParameters:
              param1:
              param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated query parameter names in a trait" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              queryParameters:
                param1:
                param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated query parameter names in a trait first optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              queryParameters:
                param1?:
                param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated query parameter names in a trait second optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              queryParameters:
                param1:
                param1?:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated query parameter names in a trait both optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              queryParameters:
                param1?:
                param1?:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated query parameter names in a trait both parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              queryParameters:
                <<parameter>>:
                <<parameter>>:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: '<<parameter>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated query parameter names in a resource type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                queryParameters?:
                  param1:
                  param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated query parameter names in a resource type first optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                queryParameters?:
                  param1?:
                  param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated query parameter names in a resource type second optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                queryParameters?:
                  param1:
                  param1?:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated query parameter names in a resource type both optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                queryParameters?:
                  param1?:
                  param1?:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated query parameter names in a resource type both parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get:
                queryParameters:
                  <<parameter>>:
                  <<parameter>>:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: '<<parameter>>'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in URI parameters" do
      it "should fail if there are repeated properties in a URI parameter in a method" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource:
          get:
            queryParameters:
              param1:
                type: string
                type: integer
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'type'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a URI parameter in a trait" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              queryParameters?:
                param1?:
                  type: string
                  type: integer
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'type'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a URI parameter in a trait first optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              queryParameters?:
                param1?:
                  enum?: [ "value" ]
                  enum: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a URI parameter in a trait second optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              queryParameters?:
                param1?:
                  enum: [ "value" ]
                  enum?: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a URI parameter in a trait both optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              queryParameters?:
                param1?:
                  enum?: [ "value" ]
                  enum?: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a URI parameter in a trait both parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              queryParameters?:
                param1?:
                  <<someParameter>>: number
                  <<someParameter>>: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: '<<someParameter>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a URI parameter in a resourceType" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                queryParameters?:
                  param1?:
                    enum: [ "value" ]
                    enum: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a URI parameter in a resourceType first optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                queryParameters?:
                  param1?:
                    enum?: [ "value" ]
                    enum: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a URI parameter in a resourceType second optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                queryParameters?:
                  param1?:
                    enum: [ "value" ]
                    enum?: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a URI parameter in a resourceType both optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                queryParameters?:
                  param1?:
                    enum?: [ "value" ]
                    enum?: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a URI parameter in a resourceType both parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                queryParameters?:
                  param1?:
                    <<someParameter>>: number
                    <<someParameter>>: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: '<<someParameter>>'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "form parameters" do
      it "should fail if there are repeated form parameter names in a method with default Media Type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        mediaType: application/json
        /resource:
          get:
            body:
              formParameters:
                param1:
                param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a trait with default Media Type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
                formParameters:
                  param1:
                  param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a trait first optional with default Media Type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
                formParameters:
                  param1?:
                  param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a trait second optional with default Media Type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
                formParameters:
                  param1:
                  param1?:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a trait both optional with default Media Type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
                formParameters:
                  param1?:
                  param1?:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a trait both parameters with default Media Type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
                formParameters:
                  <<parameter>>:
                  <<parameter>>:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: '<<parameter>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a resource type with default Media Type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body?:
                  formParameters?:
                    param1:
                    param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a resource type first optional with default Media Type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body?:
                  formParameters?:
                    param1?:
                    param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a resource type second optional with default Media Type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body?:
                  formParameters?:
                    param1:
                    param1?:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a resource type both optional with default Media Type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body?:
                  formParameters?:
                    param1?:
                    param1?:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a resource type both parameters with default Media Type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body?:
                  formParameters?:
                    <<parameter>>:
                    <<parameter>>:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: '<<parameter>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a method with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource:
          get:
            body:
             application/json:
              formParameters:
                param1:
                param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a trait with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/json:
                formParameters:
                  param1:
                  param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a trait first optional with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/json:
                formParameters:
                  param1?:
                  param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a trait second optional with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/json:
                formParameters:
                  param1:
                  param1?:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a trait both optional with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/json:
                formParameters:
                  param1?:
                  param1?:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a trait both parameters with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/json:
                formParameters:
                  <<parameter>>:
                  <<parameter>>:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: '<<parameter>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a resource type with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body?:
                 application/json:
                  formParameters?:
                    param1:
                    param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a resource type first optional with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body?:
                 application/json:
                  formParameters?:
                    param1?:
                    param1:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a resource type second optional with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body?:
                 application/json:
                  formParameters?:
                    param1:
                    param1?:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a resource type both optional with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body?:
                 application/json:
                  formParameters?:
                    param1?:
                    param1?:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: 'param1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated form parameter names in a resource type both parameters with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body?:
                 application/json:
                  formParameters?:
                    <<parameter>>:
                    <<parameter>>:
        """

        assert_raise(RamlParseError, ~r(parameter name already used: '<<parameter>>'), fn ->
          parse_string!(str)
        end)
      end


      it "should fail if there are repeated properties in a form parameter in a method with default media type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource:
          get:
            body:
              formParameters:
                param1:
                  type: number
                  type: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'type'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a trait with default media type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
                formParameters?:
                  param1?:
                    type: number
                    type: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'type'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a trait first optional with default media type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
                formParameters?:
                  param1?:
                    enum?: [ "value" ]
                    enum: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a trait second optional with default media type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
                formParameters?:
                  param1?:
                    enum: [ "value" ]
                    enum?: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a trait both optional with default media type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
                formParameters?:
                  param1?:
                    enum?: [ "value" ]
                    enum?: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a trait both parameters with default media type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
                formParameters?:
                  param1?:
                    <<someParameter>>: number
                    <<someParameter>>: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: '<<someParameter>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a resourceType with default media type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                  formParameters?:
                    param1?:
                      type: number
                      type: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'type'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a resourceType first optional with default media type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                  formParameters?:
                    param1?:
                      enum?: [ "value" ]
                      enum: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a resourceType second optional with default media type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                  formParameters?:
                    param1?:
                      enum: [ "value" ]
                      enum?: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a resourceType both optional with default media type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                  formParameters?:
                    param1?:
                      enum?: [ "value" ]
                      enum?: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a resourceType both parameters with default media type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                  formParameters?:
                    param1?:
                      <<someParameter>>: number
                      <<someParameter>>: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: '<<someParameter>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a method with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource:
          get:
            body:
             application/x-www-form-urlencoded:
              formParameters:
                param1:
                  type: number
                  type: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'type'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a trait with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/x-www-form-urlencoded:
                formParameters?:
                  param1?:
                    type: number
                    type: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'type'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a trait first optional with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/x-www-form-urlencoded:
                formParameters?:
                  param1?:
                    enum?: [ "value" ]
                    enum: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a trait second optional with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/x-www-form-urlencoded:
                formParameters?:
                  param1?:
                    enum: [ "value" ]
                    enum?: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a trait both optional with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/x-www-form-urlencoded:
                formParameters?:
                  param1?:
                    enum?: [ "value" ]
                    enum?: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a trait both parameters with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/x-www-form-urlencoded:
                formParameters?:
                  param1?:
                    <<someParameter>>: number
                    <<someParameter>>: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: '<<someParameter>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a resourceType with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 application/x-www-form-urlencoded:
                  formParameters?:
                    param1?:
                      type: number
                      type: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'type'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a resourceType first optional with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 application/x-www-form-urlencoded:
                  formParameters?:
                    param1?:
                      enum?: [ "value" ]
                      enum: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a resourceType second optional with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 application/x-www-form-urlencoded:
                  formParameters?:
                    param1?:
                      enum: [ "value" ]
                      enum?: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a resourceType both optional with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 application/x-www-form-urlencoded:
                  formParameters?:
                    param1?:
                      enum?: [ "value" ]
                      enum?: [ "value" ]
        """

        assert_raise(RamlParseError, ~r(parameter property already used: 'enum'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a form parameter in a resourceType both parameters with content type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 application/x-www-form-urlencoded:
                  formParameters?:
                    param1?:
                      <<someParameter>>: number
                      <<someParameter>>: string
        """

        assert_raise(RamlParseError, ~r(parameter property already used: '<<someParameter>>'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in content types" do
      it "should fail if there are repeated content types in a body in a resource" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource:
          get:
            body:
              application/x-www-form-urlencoded:
              application/x-www-form-urlencoded:
        """

        assert_raise(RamlParseError, ~r(property already used: 'application\/x-www-form-urlencoded'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated content types in a body in a resource type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 application/x-www-form-urlencoded:
                 application/x-www-form-urlencoded:
        """

        assert_raise(RamlParseError, ~r(property already used: 'application\/x-www-form-urlencoded'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated content types in a body in a resource type first optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 application/x-www-form-urlencoded?:
                 application/x-www-form-urlencoded:
        """

        assert_raise(RamlParseError, ~r(property already used: 'application\/x-www-form-urlencoded'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated content types in a body in a resource type second optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 application/x-www-form-urlencoded:
                 application/x-www-form-urlencoded?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'application\/x-www-form-urlencoded'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated content types in a body in a resource type both optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 application/x-www-form-urlencoded?:
                 application/x-www-form-urlencoded?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'application\/x-www-form-urlencoded'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated content types in a body in a resource type both parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 <<someContentType>>:
                 <<someContentType>>:
        """

        assert_raise(RamlParseError, ~r(property already used: '<<someContentType>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated content types in a body in a trait" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/x-www-form-urlencoded:
               application/x-www-form-urlencoded:
        """

        assert_raise(RamlParseError, ~r(property already used: 'application\/x-www-form-urlencoded'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated content types in a body in a trait first optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/x-www-form-urlencoded?:
               application/x-www-form-urlencoded:
        """

        assert_raise(RamlParseError, ~r(property already used: 'application\/x-www-form-urlencoded'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated content types in a body in a trait second optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/x-www-form-urlencoded:
               application/x-www-form-urlencoded?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'application\/x-www-form-urlencoded'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated content types in a body in a trait both optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               application/x-www-form-urlencoded?:
               application/x-www-form-urlencoded?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'application\/x-www-form-urlencoded'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated content types in a body in a trait both parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               <<someContentType>>:
               <<someContentType>>:
        """

        assert_raise(RamlParseError, ~r(property already used: '<<someContentType>>'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in body properties" do
      it "should fail if there are repeated properties in a body in a resource" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource:
          get:
            body:
              schema:
              schema:
        """

        assert_raise(RamlParseError, ~r(property already used: 'schema'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a body in a resource type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 formParameters:
                 formParameters:
        """

        assert_raise(RamlParseError, ~r(property already used: 'formParameters'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a body in a resource type first optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 formParameters?:
                 formParameters:
        """

        assert_raise(RamlParseError, ~r(property already used: 'formParameters'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a body in a resource type second optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 formParameters:
                 formParameters?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'formParameters'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a body in a resource type both optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 formParameters?:
                 formParameters?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'formParameters'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a body in a resource type both parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                body:
                 <<someContentType>>:
                 <<someContentType>>:
        """

        assert_raise(RamlParseError, ~r(property already used: '<<someContentType>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a body in a trait" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               schema:
               schema:
        """

        assert_raise(RamlParseError, ~r(property already used: 'schema'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a body in a trait first optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               formParameters?:
               formParameters:
        """

        assert_raise(RamlParseError, ~r(property already used: 'formParameters'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a body in a trait second optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               formParameters:
               formParameters?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'formParameters'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a body in a trait both optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               formParameters?:
               formParameters?:
        """

        assert_raise(RamlParseError, ~r(property already used: 'formParameters'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated properties in a body in a trait both parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              body:
               <<someContentType>>:
               <<someContentType>>:
        """

        assert_raise(RamlParseError, ~r(property already used: '<<someContentType>>'), fn ->
          parse_string!(str)
        end)
      end
    end

    describe "in header" do
      it "should fail if there are repeated header names in a method" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        /resource:
          get:
            headers:
              header1:
              header1:
        """

        assert_raise(RamlParseError, ~r(header name already used: 'header1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated header names in a trait" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              headers:
                header1:
                header1:
        """

        assert_raise(RamlParseError, ~r(header name already used: 'header1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated header names in a trait first optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              headers:
                header1?:
                header1:
        """

        assert_raise(RamlParseError, ~r(header name already used: 'header1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated header names in a trait second optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              headers:
                header1:
                header1?:
        """

        assert_raise(RamlParseError, ~r(header name already used: 'header1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated header names in a trait both optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              headers:
                header1?:
                header1?:
        """

        assert_raise(RamlParseError, ~r(header name already used: 'header1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated header names in a trait both parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        traits:
          - trait1:
              headers:
                <<headerName>>:
                <<headerName>>:
        """

        assert_raise(RamlParseError, ~r(header name already used: '<<headerName>>'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated header names in a resource type" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                headers?:
                  header1:
                  header1:
        """

        assert_raise(RamlParseError, ~r(header name already used: 'header1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated header names in a resource type first optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                headers?:
                  header1?:
                  header1:
        """

        assert_raise(RamlParseError, ~r(header name already used: 'header1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated header names in a resource type second optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                headers?:
                  header1:
                  header1?:
        """

        assert_raise(RamlParseError, ~r(header name already used: 'header1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated header names in a resource type both optional" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get?:
                headers?:
                  header1?:
                  header1?:
        """

        assert_raise(RamlParseError, ~r(header name already used: 'header1'), fn ->
          parse_string!(str)
        end)
      end

      it "should fail if there are repeated header names in a resource type both parameters" do
        str = """
        #%RAML 0.8
        ---
        title: Test
        resourceTypes:
          - type1:
              get:
                headers?:
                  <<headerName>>:
                  <<headerName>>:
        """

        assert_raise(RamlParseError, ~r(header name already used: '<<headerName>>'), fn ->
          parse_string!(str)
        end)
      end
    end
  end
end
