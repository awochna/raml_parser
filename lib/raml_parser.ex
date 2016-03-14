defmodule RamlParser do
  @moduledoc """
  Main entry point to RamlParser.
  
  ## Options

  All functions take the same options. Valid options are:
  * `validate`: (default: true) If true, RAML will be checked for validity. Any
    invalid RAML will be rejected with a RamlParseError.
  * `transform`: (default: true) If true, returned RAML structure will have default
    values and assumptions made explicit
  * `compose`: (default: false) ??? I think if this is true you get more of an AST
    than a data structure but it's not implemented and I haven't looked into the
    raml-js-parser source enough yet.
  * `applySchema`: (default: true) If true, replace references to schemas with the
    actual schema.
    """

  @spec parse_string(String.t, Keyword.t) :: {:ok, Map.t} | {:error, Exception.t}
  @doc """
  Parse a string into an RAML map. On success, returns `{:ok, raml}`, on error
  returns `{:error, error}`.
  """
  def parse_string(str, opts \\ []) do
      parse(str, opts)
  end

  @spec parse_string!(String.t, Keyword.t) :: Map.t | no_return
  @doc """
  Parse a string into an RAML map. Raises on error.
  """
  def parse_string!(str, opts \\ []) do
    case parse(str, opts) do
      {:ok, raml} -> raml
      {:error, error} -> raise error
    end
  end

  @spec parse_file(String.t, Keyword.t) :: {:ok, Map.t} | {:error, Exception.t}
  @doc """
  Parse a file at the specified path into an RAML map. On success returns
  `{:ok, raml}`, on error returns `{:error, error}`.
  """
  def parse_file(path, opts \\ []) do
    with {:ok, file} <- File.read(path) do
        parse(file, opts)
      end
  end

  @spec parse_file!(String.t, Keyword.t) :: Map.t | no_return
  @doc """
  Parse a file at the specified path into an RAML map. Raises on error.
  """
  def parse_file!(path, opts \\ []) do
    file = File.read!(path)
    case parse(file, opts) do
      {:ok, raml} -> raml
      {:error, error} -> raise error
    end
  end

  defp parse(raml, opts) do
    error = RamlParseError.exception("Not Implemented")
    {:error, error}
  end
end
