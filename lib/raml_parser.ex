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

  alias RamlParser.Validate
  alias RamlParser.Transform
  alias RamlParser.Schemas
  alias RamlParser.Parser
  
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

  def parse(yaml, opts) do
    with {:ok, yaml} <- Validate.validate_versions(yaml, opts),
    yaml = read_yaml(yaml),
    {:ok, yaml} <- Parser.add_includes(yaml),
    {:ok, yaml} <- Validate.validate_yaml(yaml, opts),
    {:ok, yaml} <- Transform.transform_yaml(yaml, opts),
    {:ok, yaml} <- Schemas.apply_schemas(yaml, opts) do
      Parser.convert_yaml(yaml)
    end
  end

  def read_yaml(yaml) do
    try do
      :yamerl_constr.string(yaml, node_mods: [RamlParser.YamerlIncludeNode],
                            detailed_constr: true)
    rescue
      e -> {:error, e}
    end
  end
end
