defmodule RamlParser.Transform do
  def transform_yaml(yaml, opts) do
    if Keyword.get(opts, :transform, true) do
      {:ok, yaml}
    else
      {:ok, yaml}
    end
  end
end
