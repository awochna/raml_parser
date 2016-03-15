defmodule RamlParser.Parser do
  import RamlParser.YamerlRecords
  import RamlParser.YamerlIncludeNode
  
  def add_includes(yaml) do
    {:ok, yaml}
  end

  def convert_yaml([doc]) do
    {:ok, do_convert(doc)}
  end

  def do_convert(yamerl_doc(root: root)) do
    do_convert(root)
  end

  def do_convert(yamerl_map(pairs: pairs)) do
    for {key, value} <- pairs, into: Map.new do
      {do_convert(key), do_convert(value)}
    end
  end

  def do_convert(yamerl_seq(entries: entries)) do
    for entry <- entries do
      do_convert(entry)
    end
  end

  def do_convert(yamerl_str(text: text)) do
    List.to_string(text)
  end

  def do_convert(yamerl_null()) do
    nil
  end

  def do_convert(yamerl_bool(value: value)) do
    value
  end

  def do_convert(yamerl_int(value: value)) do
    value
  end

  def do_convert(yamerl_float(value: value)) do
    value
  end
end
