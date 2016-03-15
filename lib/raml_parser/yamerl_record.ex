defmodule RamlParser.YamerlRecords do
  require Record
  records = Record.extract_all(from_lib: "yamerl/include/yamerl_nodes.hrl")
  for {name, opts} <- records do
    Record.defrecord(name, opts)
  end
end
