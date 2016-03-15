defmodule RamlParser.Validate do
  def validate_yaml(yaml, opts) do
    if Keyword.get(opts, :validate, true) do
      {:ok, yaml}
    else
      {:ok, yaml}
    end
  end

  def validate_versions(yaml, opts) do
    if Keyword.get(opts, :validate, true) do
      with raml_version = Regex.run(~r/#%\s*RAML\s+(.+)/, yaml,
                                      capture: :all_but_first),
      yaml_version = Regex.run(~r/%YAML\s+(.+)/, yaml,
                                 capture: :all_but_first),
      :ok <- validate_raml_version(raml_version),
      :ok <- validate_yaml_version(yaml_version), do: {:ok, yaml}
    else
      {:ok, yaml}
    end
  end

  defp validate_raml_version(raml_version) do
    if raml_version == ["0.8"] do
      :ok
    else
      message = "Unsupported RAML version: '#%RAML #{hd(raml_version)}'"
      error = RamlParseError.exception(message)
      {:error, error}
    end
  end

  defp validate_yaml_version(yaml_version) do
    case yaml_version do
      ["1.2"] -> :ok
      nil -> :ok
      _ ->
        message = "found incompatible YAML document (version 1.2 is required)"
        error = RamlParseError.exception(message)
        {:error, error}
    end
  end
end
