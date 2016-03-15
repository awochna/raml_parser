defmodule RamlParser.Schemas do
  def apply_schemas(yaml, opts) do
    if Keyword.get(opts, :applySchemas, true) do
      {:ok, yaml}
    else
      {:ok, yaml}
    end
  end
end
